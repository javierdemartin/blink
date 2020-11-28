//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////

// TODO: Re-draw when appears

import MBProgressHUD
import SwiftUI
import UIKit
import Combine

class SessionsCarrouselViewController: UIHostingController<AnyView> {
  required init?(coder: NSCoder) {
    
    super.init(coder: coder)
  }
  
  init(rootView: AnyView, environmentSettings: DashboardBrain) {
    let listView = rootView.environmentObject(environmentSettings)
    super.init(rootView: AnyView(listView))
  }
  
  override init(rootView: AnyView) {
    
    let listView = rootView.environmentObject(DashboardBrain())
    super.init(rootView: AnyView(listView))
  }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

class SpaceController: UIViewController {
  
  var cancellableBag: Set<AnyCancellable> = []
  
  lazy var dashboardBrain = DashboardBrain()
  
  private lazy var bottomLeftStackView: UIStackView = {
    
    let stackView = UIStackView(arrangedSubviews: [dashboardHostingController.view, terminalsCarrousel.view])
    stackView.alignment = UIStackView.Alignment.leading
    stackView.axis = NSLayoutConstraint.Axis.vertical
    stackView.isHidden = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    
    return stackView
  }()
  
  lazy var dashboardHostingController: SessionsCarrouselViewController = {
    let viewController = SessionsCarrouselViewController(rootView: AnyView(BKDashboard()), environmentSettings: dashboardBrain)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.backgroundColor = UIColor.clear
    
    return viewController
  }()
  
  var common = LongProcessesView()
  
//  lazy var commonActionsHostingController: UIHostingController<CommonActions> = {
  lazy var commonActionsHostingController: SessionsCarrouselViewController = {
    
    let hostingController = SessionsCarrouselViewController(rootView: AnyView(LongProcessesView()), environmentSettings: dashboardBrain)
    hostingController.view.backgroundColor = UIColor.clear
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    return hostingController
  }()

  /**
   Hosts all of the open terminals and the shortcut to open a new tab
   */
  lazy var terminalsCarrousel: SessionsCarrouselViewController = {
    let viewController = SessionsCarrouselViewController(rootView: AnyView(TerminalsCarrousel()), environmentSettings: dashboardBrain)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.backgroundColor = UIColor.clear
    
    return viewController
  }()

  
  var initialBottomLeftPosition = CGPoint()  // The initial center point of the view.
  var initialVerticalBottomLeftPosition = CGPoint()  // The initial center point of the view.
  var initialTopRightPosition = CGPoint()
  var translatedBottomLeftPosition = CGPoint()
  var translatedVerticalBottomLeftPosition = CGPoint()
  var translatedTopRightPosition = CGPoint()
  
  struct UIState: UserActivityCodable {
    var keys: [UUID] = []
    var currentKey: UUID? = nil
    var bgColor: CodableColor? = nil
    
    static var activityType: String { "space.ctrl.ui.state" }
  }

  final private lazy var _viewportsController = UIPageViewController(
    transitionStyle: .scroll,
    navigationOrientation: .horizontal,
    options: [.spineLocation: UIPageViewController.SpineLocation.mid]
  )
  
  var sceneRole: UISceneSession.Role = UISceneSession.Role.windowApplication
  
  private var _viewportsKeys = [UUID]()
  private var _termControllers: Set<TermController> = Set()
  private var _currentKey: UUID? = nil
  
  private var _hud: MBProgressHUD? = nil
  private let _commandsHUD = CommandsHUGView(frame: .zero)
  
  private var _overlay = UIView()
  private var _spaceControllerAnimating: Bool = false
  var stuckKeyCode: KeyCode? = nil
  
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    guard let window = view.window
    else {
      return
    }
    
    if window.screen === UIScreen.main {
      var insets = UIEdgeInsets.zero
      insets.bottom = LayoutManager.mainWindowKBBottomInset()
      _overlay.frame = view.bounds.inset(by: insets)
    } else {
      _overlay.frame = view.bounds
    }
    
    _commandsHUD.setNeedsLayout()
  }
  
  @objc func _relayout() {
    guard
      let window = view.window,
      window.screen === UIScreen.main
    else {
      return
    }
    
    view.setNeedsLayout()
  }
  
  @objc private func _setupAppearance() {
    self.view.tintColor = .cyan
    switch BKDefaults.keyboardStyle() {
    case .light:
      overrideUserInterfaceStyle = .light
    case .dark:
      overrideUserInterfaceStyle = .dark
    default:
      overrideUserInterfaceStyle = .unspecified
    }
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    _setupAppearance()
    
    dashboardBrain.dashboardAction.sink(receiveValue: { a in
        
      switch a {
      
      case .newTab:
        self.newShellAction()
      case .enableGeoLock:
        break
      case .stopGeoLock:
        break
      case .geoLock:
        if GeoManager.shared().traking {
          GeoManager.shared().stop()
          
          self.dashboardBrain.dashboardConsecuence.send(.geoLockStatus(status: "Stop"))
        } else {
          GeoManager.shared().start()
          GeoManager.shared().lock(inDistance: 200)
          self.dashboardBrain.dashboardConsecuence.send(.geoLockStatus(status: "Start (200 m)"))
        }
      case .iterateScreenMode:
        
        var layoutMode = BKDefaults.layoutMode().rawValue
        
        if layoutMode != BKLayoutMode.safeFit.rawValue {
          layoutMode += 1
        } else {
          layoutMode = 0
        }
        
        BKDefaults.setLayoutMode(BKLayoutMode(rawValue: layoutMode)!)
        BKDefaults.save()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: BKAppearanceChanged), object: self)
        
        self.common.settings.dashboardConsecuence.send(.screenMode(status: ScreenAppearanceTranslator(rawValue: layoutMode)!.description))
      case .pasteOnTerm(text: let contents):
        self.currentTerm()?.termDevice.write(contents)
      }
      
    }).store(in: &cancellableBag)
    
    view.isOpaque = true
    
    _viewportsController.view.isOpaque = true
    _viewportsController.dataSource = self
    _viewportsController.delegate = self
    
    
    addChild(_viewportsController)
    
    if let v = _viewportsController.view {
      v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      v.layoutMargins = .zero
      v.frame = view.bounds
      view.addSubview(v)
    }
    
    _viewportsController.didMove(toParent: self)
    
    _overlay.isUserInteractionEnabled = false
    view.addSubview(_overlay)
    
    _commandsHUD.delegate = self
    _registerForNotifications()
    
    if _viewportsKeys.isEmpty {
      _createShell(userActivity: nil, animated: false)
    } else if let key = _currentKey {
      let term: TermController = SessionRegistry.shared[key]
      term.delegate = self
      _termControllers.insert(term)
      term.bgColor = view.backgroundColor ?? .black
      _viewportsController.setViewControllers([term], direction: .forward, animated: false)
    }
    
    let hideGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDashboardGesture(_:)))
    bottomLeftStackView.addGestureRecognizer(hideGesture)
    
    let guide = view.safeAreaLayoutGuide
    
    view.addSubview(commonActionsHostingController.view)
    addChild(commonActionsHostingController)
    view.addSubview(bottomLeftStackView)
      
    NSLayoutConstraint.activate([
      commonActionsHostingController.view.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
      bottomLeftStackView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
      bottomLeftStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
      bottomLeftStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor)
    ])
    
    if UIDevice.current.userInterfaceIdiom == .pad {
      
      
      NSLayoutConstraint.activate([
        commonActionsHostingController.view.topAnchor.constraint(equalTo: guide.topAnchor)
      ])
    }

    /// UI layout specific constraints for iPhones
    else if UIDevice.current.userInterfaceIdiom == .phone {

      /// Stack up the layout vertically
      NSLayoutConstraint.activate([
        commonActionsHostingController.view.bottomAnchor.constraint(equalTo: bottomLeftStackView.topAnchor)
      ])
    }
    
    dashboardHostingController.view.frame = view.bounds
    commonActionsHostingController.view.frame = view.bounds
    terminalsCarrousel.view.frame = view.bounds
    bottomLeftStackView.frame = view.bounds
    
    /// Hide the Dashboard on first appearance
//    showDashboardProgramatically()
  }
  
  


  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    if view.window?.isKeyWindow == true {
      DispatchQueue.main.async {
        
//        self.currentTerm()?.termDevice.view?.webView?.kbView.reset()
//        SmarterTermInput.shared.contentView()?.reloadInputViews()
      }
    }
  }
  
  override var editingInteractionConfiguration: UIEditingInteractionConfiguration {
    DispatchQueue.main.async {
      self._attachHUD()
    }
    return .default
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  func _registerForNotifications() {
    let nc = NotificationCenter.default
    
    nc.addObserver(self,
                   selector: #selector(_didBecomeKeyWindow),
                   name: UIWindow.didBecomeKeyNotification,
                   object: nil)
    
    nc.addObserver(self, selector: #selector(_relayout),
                   name: NSNotification.Name(rawValue: LayoutManagerBottomInsetDidUpdate),
                   object: nil)
    
    nc.addObserver(self, selector: #selector(_setupAppearance),
                   name: NSNotification.Name(rawValue: BKAppearanceChanged),
                   object: nil)
    
  }
  
  private func _attachHUD() {
    if
      sceneRole == .windowApplication,
      let win = view.window?.windowScene?.windows.last,
      win !== view.window {
      _commandsHUD.attachToWindow(inputWindow: win)
    }
  }
  
  @objc func _didBecomeKeyWindow() {
    guard
      let window = view.window,
      window.isKeyWindow
    else {
      currentDevice?.blur()
      return
    }
    
    _focusOnShell()
  }
  
  func _createShell(
    userActivity: NSUserActivity?,
    animated: Bool,
    completion: ((Bool) -> Void)? = nil)
  {
    let term = TermController(sceneRole: sceneRole)
    term.delegate = self
    term.userActivity = userActivity
    term.bgColor = view.backgroundColor ?? .black
    _termControllers.insert(term)
    
    if let currentKey = _currentKey,
      let idx = _viewportsKeys.firstIndex(of: currentKey)?.advanced(by: 1) {
      _viewportsKeys.insert(term.meta.key, at: idx)
    } else {
      _viewportsKeys.insert(term.meta.key, at: _viewportsKeys.count)
    }
    
    SessionRegistry.shared.track(session: term)
    
    _currentKey = term.meta.key
    
    _viewportsController.setViewControllers([term], direction: .forward, animated: animated) { (didComplete) in
      self._displayHUD()
      self._attachInputToCurrentTerm()
      completion?(didComplete)
    }
  }
  
  func _closeCurrentSpace() {
    currentTerm()?.terminate()
    _removeCurrentSpace()
  }
  
  private func _removeCurrentSpace(attachInput: Bool = true) {
    guard
      let currentKey = _currentKey,
      let idx = _viewportsKeys.firstIndex(of: currentKey)
    else {
      return
    }
    currentTerm()?.delegate = nil
    SessionRegistry.shared.remove(forKey: currentKey)
    _viewportsKeys.remove(at: idx)
    if _viewportsKeys.isEmpty {
      _createShell(userActivity: nil, animated: true)
      return
    }

    let direction: UIPageViewController.NavigationDirection
    let term: TermController
    
    if idx < _viewportsKeys.endIndex {
      direction = .forward
      term = SessionRegistry.shared[_viewportsKeys[idx]]
    } else {
      direction = .reverse
      term = SessionRegistry.shared[_viewportsKeys[idx - 1]]
    }
    term.bgColor = view.backgroundColor ?? .black
    
    self._currentKey = term.meta.key
    
    _spaceControllerAnimating = true
    _viewportsController.setViewControllers([term], direction: direction, animated: true) { (didComplete) in
      self._displayHUD()
      if attachInput {
        self._attachInputToCurrentTerm()
      }
      self._spaceControllerAnimating = false
    }
  }
  
  @objc func _focusOnShell() {
    _attachInputToCurrentTerm()
  }
  
  private func _attachInputToCurrentTerm() {
    guard let device = currentDevice else {
      return
    }

    let input = KBTracker.shared.input
    KBTracker.shared.attach(input: device.view?.webView)

    if !device.view.isReady {
      return
    }
    
    device.attachInput(device.view.webView)
    device.view.webView.reportFocus(true)
    device.focus()
    if input != KBTracker.shared.input { //&& input?.window != KBTracker.shared.input?.window {
      input?.reportFocus(false)
    }
  }
  
  var currentDevice: TermDevice? {
    currentTerm()?.termDevice
  }
  
  /**
   Triggered on: terminal resize, shell move, shell creation, remove current term
   */
  private func _displayHUD() {
    _hud?.hide(animated: false)
    
    guard let term = currentTerm() else {
      return
    }
    
    let params = term.sessionParams
    
    if let bgColor = term.view.backgroundColor, bgColor != .clear {
      view.backgroundColor = bgColor
      _viewportsController.view.backgroundColor = bgColor
      view.window?.backgroundColor = bgColor
    }
    
    let hud = MBProgressHUD.showAdded(to: _overlay, animated: _hud == nil)
    
    hud.mode = .customView
    hud.bezelView.color = .darkGray
    hud.contentColor = .white
    hud.isUserInteractionEnabled = false
    hud.alpha = 0.6
    
    let pages = UIPageControl()
    pages.currentPageIndicatorTintColor = .blinkHudDot
    pages.numberOfPages = _viewportsKeys.count
    let pageNum = _viewportsKeys.firstIndex(of: term.meta.key)
    pages.currentPage = pageNum ?? NSNotFound
    
    hud.customView = pages
    
    let title = term.title?.isEmpty == true ? nil : term.title
    
    var sceneTitle = "[\(pageNum == nil ? 1 : pageNum! + 1) of \(_viewportsKeys.count)] \(title ?? "blink")"
    
    if params.rows == 0 && params.cols == 0 {
      hud.label.numberOfLines = 1
      hud.label.text = title ?? "blink"
    } else {
      let geometry = "\(params.cols)×\(params.rows)"
      hud.label.numberOfLines = 2
      hud.label.text = "\(title ?? "blink")\n\(geometry)"
      
      sceneTitle += " | " + geometry
    }
    
    _hud = hud
    hud.hide(animated: true, afterDelay: 1)
    
    view.window?.windowScene?.title = sceneTitle
    _commandsHUD.updateHUD()
    
    // Triggered on each terminal screen to detect possible new links to interact with
    getInterestingLinks()
  }
  
}

extension SpaceController: UIStateRestorable {
  func restore(withState state: UIState) {
    _viewportsKeys = state.keys
    _currentKey = state.currentKey
    if let bgColor = UIColor(codableColor: state.bgColor) {
      view.backgroundColor = bgColor
    }
  }
  
  func dumpUIState() -> UIState {
    UIState(keys: _viewportsKeys,
            currentKey: _currentKey,
            bgColor: CodableColor(uiColor: view.backgroundColor)
    )
  }
  
  @objc static func onDidDiscardSceneSessions(_ sessions: Set<UISceneSession>) {
    let registry = SessionRegistry.shared
    sessions.forEach { session in
      guard
        let uiState = UIState(userActivity: session.stateRestorationActivity)
      else {
        return
      }
      
      uiState.keys.forEach { registry.remove(forKey: $0) }
    }
  }
}

extension SpaceController: UIPageViewControllerDelegate {
  public func pageViewController(
    _ pageViewController: UIPageViewController,
    didFinishAnimating finished: Bool,
    previousViewControllers: [UIViewController],
    transitionCompleted completed: Bool) {
    guard completed else {
      return
    }
    
    guard let termController = pageViewController.viewControllers?.first as? TermController
    else {
      return
    }
    _currentKey = termController.meta.key
    _displayHUD()
    _attachInputToCurrentTerm()
  }
}

extension SpaceController: UIPageViewControllerDataSource {
  private func _controller(controller: UIViewController, advancedBy: Int) -> UIViewController? {
    guard let ctrl = controller as? TermController else {
      return nil
    }
    let key = ctrl.meta.key
    guard
      let idx = _viewportsKeys.firstIndex(of: key)?.advanced(by: advancedBy),
      _viewportsKeys.indices.contains(idx)
    else {
      return nil
    }
    
    let newKey = _viewportsKeys[idx]
    let newCtrl: TermController = SessionRegistry.shared[newKey]
    newCtrl.delegate = self
    newCtrl.bgColor = view.backgroundColor ?? .black
    _termControllers.insert(newCtrl)
    return newCtrl
  }
  
  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    _controller(controller: viewController, advancedBy: -1)
  }
  
  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    _controller(controller: viewController, advancedBy: 1)
  }
  
}

extension SpaceController: TermControlDelegate {
  
  func terminalHangup(control: TermController) {
    if currentTerm() == control {
      _closeCurrentSpace()
    }
  }
  
  func terminalDidResize(control: TermController) {
    if currentTerm() == control {
      _displayHUD()
    }
  }
}

// MARK: General tunning

extension SpaceController {
  public override var prefersStatusBarHidden: Bool { true }
  public override var prefersHomeIndicatorAutoHidden: Bool { true }
}


// MARK: Commands


extension SpaceController {
  
  var foregroundActive: Bool {
    view.window?.windowScene?.activationState == UIScene.ActivationState.foregroundActive
  }
  
  public override var keyCommands: [UIKeyCommand]? {
    guard
      let input = KBTracker.shared.input,
      foregroundActive
    else {
      return []
    }
    
    if let keyCode = stuckKeyCode {
      return [UIKeyCommand(input: "", modifierFlags: keyCode.modifierFlags, action: #selector(onStuckOpCommand))]
    }
    
    return input.blinkKeyCommands
  }
  
  @objc func onStuckOpCommand() {
    stuckKeyCode = nil
    presentedViewController?.dismiss(animated: true)
    _focusOnShell()
  }
  
  @objc func _onBlinkCommand(_ cmd: BlinkCommand) {
    guard foregroundActive,
      let input = currentDevice?.view?.webView else {
      return
    }

    input.reportStateReset()
    switch cmd.bindingAction {
    case .hex(let hex, comment: _):
      input.reportHex(hex)
      break;
    case .press(let keyCode, mods: let mods):
      input.reportPress(UIKeyModifierFlags(rawValue: mods), keyId: keyCode.id)
      break;
    case .command(let c):
      _onCommand(c)
    default:
      break;
    }
  }
  
  func _onCommand(_ cmd: Command) {
    guard foregroundActive else {
      return
    }

    switch cmd {
//    case .openDashboard: showDashboard()
    case .configShow: showConfigAction()
    case .tab1: _moveToShell(idx: 0)
    case .tab2: _moveToShell(idx: 1)
    case .tab3: _moveToShell(idx: 2)
    case .tab4: _moveToShell(idx: 3)
    case .tab5: _moveToShell(idx: 4)
    case .tab6: _moveToShell(idx: 5)
    case .tab7: _moveToShell(idx: 6)
    case .tab8: _moveToShell(idx: 7)
    case .tab9: _moveToShell(idx: 8)
    case .tab10: _moveToShell(idx: 9)
    case .tab11: _moveToShell(idx: 10)
    case .tab12: _moveToShell(idx: 11)
    case .tabClose: _closeCurrentSpace()
    case .tabMoveToOtherWindow: _moveToOtherWindowAction()
    case .tabNew: newShellAction()
    case .tabNext: _advanceShell(by: 1)
    case .tabPrev: _advanceShell(by: -1)
    case .tabNextCycling: _advanceShellCycling(by: 1)
    case .tabPrevCycling: _advanceShellCycling(by: -1)
    case .tabLast: _moveToLastShell()
    case .windowClose: _closeWindowAction()
    case .windowFocusOther: _focusOtherWindowAction()
    case .windowNew: _newWindowAction()
    case .clipboardCopy: KBTracker.shared.input?.copy(self)
    case .clipboardPaste: KBTracker.shared.input?.paste(self)
    case .selectionGoogle: KBTracker.shared.input?.googleSelection(self)
    case .selectionStackOverflow: KBTracker.shared.input?.soSelection(self)
    case .selectionShare: KBTracker.shared.input?.shareSelection(self)
    case .zoomIn: currentTerm()?.termDevice.view?.increaseFontSize()
    case .zoomOut: currentTerm()?.termDevice.view?.decreaseFontSize()
    case .zoomReset: currentTerm()?.termDevice.view?.resetFontSize()
    case .openDashboard: showDashboardProgramatically()
    case .openSessionsCarrousel: showSessionsCarrouselProgramatically()
    }
  }
  
  @objc func focusOnShellAction() {
    KBTracker.shared.input?.reset()
    _focusOnShell()
  }
  
  @objc public func scaleWithPich(_ pinch: UIPinchGestureRecognizer) {
    currentTerm()?.scaleWithPich(pinch)
  }
  
  @objc func newShellAction() {
    _createShell(userActivity: nil, animated: true)
  }
  
  @objc func closeShellAction() {
    _closeCurrentSpace()
  }
  
  func cleanupControllers() {
    for c in _termControllers {
      if c.view?.superview == nil {
        if c.removeFromContainer() {
          _termControllers.remove(c)
        }
      }
      if c.view?.window != view.window {
        _termControllers.remove(c)
      }
    }
  }

  private func _focusOtherWindowAction() {
    
    var sessions = _activeSessions()
    
    guard
      sessions.count > 1,
      let session = view.window?.windowScene?.session,
      let idx = sessions.firstIndex(of: session)?.advanced(by: 1)
    else  {
      if currentTerm()?.termDevice.view?.isFocused() == true {
        _ = currentTerm()?.termDevice.view?.webView?.resignFirstResponder()
      } else {
        _focusOnShell()
      }
      return
    }

    if
      let shadowWindow = ShadowWindow.shared,
      let shadowScene = shadowWindow.windowScene,
      let window = self.view.window,
      shadowScene == window.windowScene,
      shadowWindow !== window {
      shadowWindow.makeKeyAndVisible()
      shadowWindow.spaceController._focusOnShell()
      return
    }
          
    sessions = sessions.filter { $0.role != .windowExternalDisplay }
    
    let nextSession: UISceneSession
    if idx < sessions.endIndex {
      nextSession = sessions[idx]
    } else {
      nextSession = sessions[0]
    }
    
    if
      let scene = nextSession.scene as? UIWindowScene,
      let delegate = scene.delegate as? SceneDelegate,
      let window = delegate.window,
      let spaceCtrl = window.rootViewController as? SpaceController {

      if window.isKeyWindow {
        spaceCtrl._focusOnShell()
      } else {
        window.makeKeyAndVisible()
      }
    } else {
      UIApplication.shared.requestSceneSessionActivation(nextSession, userActivity: nil, options: nil, errorHandler: nil)
    }
  }
  
  private func _moveToOtherWindowAction() {
    var sessions = _activeSessions()
    
    guard
      sessions.count > 1,
      let session = view.window?.windowScene?.session,
      let idx = sessions.firstIndex(of: session)?.advanced(by: 1),
      let term = currentTerm(),
      _spaceControllerAnimating == false
    else  {
        return
    }
    
    if
      let shadowWindow = ShadowWindow.shared,
      let shadowScene = shadowWindow.windowScene,
      let window = self.view.window,
      shadowScene == window.windowScene,
      shadowWindow !== window {
      
      _removeCurrentSpace(attachInput: false)
      shadowWindow.makeKey()
      shadowWindow.spaceController._addTerm(term: term)
      return
    }
          
    sessions = sessions.filter { $0.role != .windowExternalDisplay }
    
    let nextSession: UISceneSession
    if idx < sessions.endIndex {
      nextSession = sessions[idx]
    } else {
      nextSession = sessions[0]
    }
    
    guard
      let nextScene = nextSession.scene as? UIWindowScene,
      let delegate = nextScene.delegate as? SceneDelegate,
      let nextWindow = delegate.window,
      let nextSpaceCtrl = nextWindow.rootViewController as? SpaceController,
      nextSpaceCtrl._spaceControllerAnimating == false
    else {
      return
    }
    

    _removeCurrentSpace(attachInput: false)
    nextSpaceCtrl._addTerm(term: term)
    nextWindow.makeKey()
  }
  
  func _activeSessions() -> [UISceneSession] {
    Array(UIApplication.shared.openSessions)
      .filter({ $0.scene?.activationState == .foregroundActive || $0.scene?.activationState == .foregroundInactive })
      .sorted(by: { $0.persistentIdentifier < $1.persistentIdentifier })
  }
  
  @objc func _newWindowAction() {
    UIApplication
      .shared
      .requestSceneSessionActivation(nil,
                                     userActivity: nil,
                                     options: nil,
                                     errorHandler: nil)
  }
  
  @objc func _closeWindowAction() {
    guard
      let session = view.window?.windowScene?.session,
      session.role == .windowApplication // Can't close windows on external monitor
    else {
      return
    }
    
    // try to focus on other session before closing
    _focusOtherWindowAction()
    
    UIApplication
      .shared
      .requestSceneSessionDestruction(session,
                                      options: nil,
                                      errorHandler: nil)
  }
  
  @objc func showConfigAction() {
    if let shadowWindow = ShadowWindow.shared,
      view.window == shadowWindow {
      
      _ = currentDevice?.view?.webView.resignFirstResponder()
      
      let spCtrl = shadowWindow.windowScene?.windows.first?.rootViewController as? SpaceController
      spCtrl?.showConfigAction()
      
      return
    }
    
    DispatchQueue.main.async {
      let storyboard = UIStoryboard(name: "Settings", bundle: nil)
      let vc = storyboard.instantiateViewController(identifier: "NavSettingsController")
      self.present(vc, animated: true, completion: nil)
    }
  }
  
  private func _addTerm(term: TermController, animated: Bool = true) {
    SessionRegistry.shared.track(session: term)
    term.delegate = self
    _termControllers.insert(term)
    _viewportsKeys.append(term.meta.key)
    _moveToShell(key: term.meta.key, animated: animated)
  }
  
  private func _moveToShell(idx: Int, animated: Bool = true) {
    guard _viewportsKeys.indices.contains(idx) else {
      return
    }

    let key = _viewportsKeys[idx]
    
    _moveToShell(key: key, animated: animated)
  }
  
  private func _moveToLastShell(animated: Bool = true) {
    _moveToShell(idx: _viewportsKeys.count - 1)
  }
  
  @objc func moveToShell(key: String?) {
    guard
      let key = key,
      let uuidKey = UUID(uuidString: key)
    else {
      return
    }
    _moveToShell(key: uuidKey, animated: true)
  }
  
  private func _moveToShell(key: UUID, animated: Bool = true) {
    guard
      let currentKey = _currentKey,
      let currentIdx = _viewportsKeys.firstIndex(of: currentKey),
      let idx = _viewportsKeys.firstIndex(of: key)
    else {
      return
    }
    
    let term: TermController = SessionRegistry.shared[key]
    let direction: UIPageViewController.NavigationDirection = currentIdx < idx ? .forward : .reverse

    _spaceControllerAnimating = true
    _viewportsController.setViewControllers([term], direction: direction, animated: animated) { (didComplete) in
      self._currentKey = term.meta.key
      self._displayHUD()
      self._attachInputToCurrentTerm()
      self._spaceControllerAnimating = false
    }
  }
  
  private func _advanceShell(by: Int, animated: Bool = true) {
    guard
      let currentKey = _currentKey,
      let idx = _viewportsKeys.firstIndex(of: currentKey)?.advanced(by: by)
    else {
      return
    }
        
    _moveToShell(idx: idx, animated: animated)
  }
  
  private func _advanceShellCycling(by: Int, animated: Bool = true) {
    guard
      let currentKey = _currentKey,
      _viewportsKeys.count > 1
    else {
      return
    }
    
    if let idx = _viewportsKeys.firstIndex(of: currentKey)?.advanced(by: by),
      idx >= 0 && idx < _viewportsKeys.count {
      _moveToShell(idx: idx, animated: animated)
      return
    }
    
    _moveToShell(idx: by > 0 ? 0 : _viewportsKeys.count - 1, animated: animated)
  }
}

extension SpaceController: CommandsHUDViewDelegate {
  @objc func currentTerm() -> TermController? {
    if let currentKey = _currentKey {
      return SessionRegistry.shared[currentKey]
    }
    return nil
  }
  
  @objc func spaceController() -> SpaceController? { self }
}

// MARK: Dashboard

/**
 Manage dashboard gestures
 */
extension SpaceController {
  
  /**
   Executed when the `KeyBindingAction.openSessionsCarrousel` keyboard shortcut is invoked.
   
   If the Dashboard is hidden when hitting the keyboard shortcut it's also needed to bring it into view and then show the Carrousel
   */
  @objc func showSessionsCarrouselProgramatically() {
    
    /// Dashboard UIStackView is hidden
    if self.bottomLeftStackView.isHidden {
      
      /// Bring up to view the UIStackView not caring if the Terminal Carrousel is hidden
      showDashboardProgramatically()
      
      /// If the Terminal Carrousel is hidden animate its appearance
      if self.terminalsCarrousel.view.isHidden {
        /// View is about to appear
        self.terminalsCarrousel.view.fadeIn(0.15, onCompletion: {
          self.bottomLeftStackView.layoutIfNeeded()
        })
      }
    }
    
    /// Dashboard UIStackView is visible, animate the appearance of the Terminal Carrousel
    else {
      if self.terminalsCarrousel.view.isHidden {
        /// View is about to appear
        self.terminalsCarrousel.view.fadeIn(0.15, onCompletion: {
          self.bottomLeftStackView.layoutIfNeeded()
        })
      } else {
        /// View is about to be hidden
        self.terminalsCarrousel.view.fadeOut(0.15, onCompletion: {
          self.bottomLeftStackView.layoutIfNeeded()
        })
      }
    }
  }
  
  /**
   Runs `term_interestingSpots()` from `term.js` through `TermView.m`.
   
   Called whenever a tab comes on/goes scope to display intersting links. The obtained URLs are
   */
  func getInterestingLinks() {
    self.currentTerm()?.termDevice.view?.getInterestingLinks({ result in
      
      guard let result = result else { return }
      
      let detectedUrls: [String] = Array(Set((result.compactMap({ $0 as? NSDictionary }).compactMap { $0["url"] as? String }))).reversed()

      // Publish changes on main thread
      DispatchQueue.main.async {
        self.dashboardBrain.urls = detectedUrls
      }
    })
  }
  
  /**
   Executed when the `KeyBindingAction.openDashboard` keyboard shortcut is invoked
   */
  @objc func showDashboardProgramatically() {
    
    self.view.layer.removeAllAnimations()
    self.bottomLeftStackView.layer.removeAllAnimations()
    self.commonActionsHostingController.view.layer.removeAllAnimations()
    
    // Animate the appearing/disappearing of the view with some springiness added to it
    UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseIn, animations: {
      if self.bottomLeftStackView.isHidden {
        
        self.getInterestingLinks()
        
        self.bottomLeftStackView.center.x = self.bottomLeftStackView.frame.size.width/2
        self.commonActionsHostingController.view.center.x = self.view.frame.width - self.commonActionsHostingController.view.frame.width / 2
        self.bottomLeftStackView.fadeIn()
        
        self.commonActionsHostingController.view.fadeIn()
      } else {
        self.bottomLeftStackView.center.x = -1 * self.bottomLeftStackView.frame.size.width/2
        self.commonActionsHostingController.view.center.x = self.view.frame.width + self.commonActionsHostingController.view.frame.width / 2
        self.bottomLeftStackView.fadeOut(0.15, onCompletion: {
          self.bottomLeftStackView.layoutIfNeeded()
        })
        self.commonActionsHostingController.view.fadeOut(0.15, onCompletion: {
          self.commonActionsHostingController.view.layoutIfNeeded()
        })
      }
    })
  }
  
  /**
   Gesture recognizer to move out the "Blink Dashboard" hidden from the left side into view. Called from `WKWebView` and handled here.
   */
  @objc private func handleDashboardGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    
    guard let panDirection = gestureRecognizer.direction else { return }
    
    if panDirection == .left || panDirection == .right {
      
      /// If the UIStackView is already on screen and the user tries to drag it
      /// to the right side cancel the gesture as it's already on screen
      if bottomLeftStackView.alpha == 1 && panDirection == .right { return }
      
      switch gestureRecognizer.state {
      case .began:
        
        /// As views are out of screen they've been hidden, before animating their appearance unhide them
        bottomLeftStackView.isHidden = false
        commonActionsHostingController.view.isHidden = false
        
        getInterestingLinks()
        
        initialBottomLeftPosition.x = bottomLeftStackView.frame.origin.x
        initialTopRightPosition = commonActionsHostingController.view.frame.origin
      case .ended:
        
        var finalBottomLeftSnapPosition = CGPoint(x: translatedBottomLeftPosition.x, y: initialBottomLeftPosition.y)
        var finalTopRightSnapPosition = CGPoint(x: translatedTopRightPosition.x, y: initialTopRightPosition.y)
        
        /// View is about to show up, bringing it from the left side
        if translatedBottomLeftPosition.x > initialBottomLeftPosition.x {
          
          finalBottomLeftSnapPosition.x = 0.0
          finalTopRightSnapPosition.x = view.frame.width - 1 * commonActionsHostingController.view.frame.width
          
          // Animate the appearing/disappearing of the view with some springiness added to it
          UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.4, options: .curveEaseOut, animations: {
            self.bottomLeftStackView.frame.origin.x = finalBottomLeftSnapPosition.x
            self.commonActionsHostingController.view.frame.origin.x = finalTopRightSnapPosition.x
            self.bottomLeftStackView.fadeIn()
            self.commonActionsHostingController.view.fadeIn()
          })
        }
        /// View is about to be hidden
        else if panDirection == .left {
          
          finalBottomLeftSnapPosition.x = -1 * dashboardHostingController.view.frame.width
          finalTopRightSnapPosition.x = self.view.frame.width
                                          + commonActionsHostingController.view.frame.width
          
          // Animate the appearance/disappearance of the view with some springiness added to it
          UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
            self.bottomLeftStackView.frame.origin.x = finalBottomLeftSnapPosition.x
            self.commonActionsHostingController.view.frame.origin.x = finalTopRightSnapPosition.x
            self.bottomLeftStackView.fadeOut()
            self.commonActionsHostingController.view.fadeOut()
          })
        }
        
      case .changed:
        
        /// Progressivelly increase alpha when the view is hidden so the appearance is progressivelly smooth
        var alphaPercentage = abs(gestureRecognizer.translation(in: self.view).x / bottomLeftStackView.frame.width)
        
        /// When dragging leftwards alpha decreases from 1 to 0
        if panDirection == .left {
          alphaPercentage = 1 - alphaPercentage
        }
        
        translatedBottomLeftPosition.x = initialBottomLeftPosition.x
                                          + gestureRecognizer.translation(in: self.view).x
        translatedTopRightPosition.x = initialTopRightPosition.x
                                        - gestureRecognizer.translation(in: self.view).x * alphaPercentage
        
        bottomLeftStackView.frame.origin.x = translatedBottomLeftPosition.x
        commonActionsHostingController.view.frame.origin.x = translatedTopRightPosition.x
        
      default:
        break
      }
    }
    /// Handle the dragging gestures for the terminals carrousel
    else if panDirection == .up || panDirection == .down {
      
      /// If the terminal carrousel is already open and the detected gesture is upwards don't move the view
      /// and cancel the action
      if panDirection == .up && !terminalsCarrousel.view.isHidden { return }
      
      switch gestureRecognizer.state {
      case .began:
        initialVerticalBottomLeftPosition = self.bottomLeftStackView.center
        
      /// Match the ending position depending on the gesture the user has done
      case .ended:
        
        if panDirection == .down {
          /// Swipe down gesture
          self.terminalsCarrousel.view.fadeOut(0.15, onCompletion: {
            self.bottomLeftStackView.layoutIfNeeded()
            self.terminalsCarrousel.view.layoutIfNeeded()
          })
          
        }  else {
          /// Swipe up gesture
          self.terminalsCarrousel.view.fadeIn(0.15, onCompletion: {
            self.bottomLeftStackView.layoutIfNeeded()
            self.terminalsCarrousel.view.layoutIfNeeded()
          })
        }
        
      /// Follow the finger's movement when the gesture is active
      case .changed:
        
        // If pan direction is downwards start changing the apha
        var alphaPercentage = abs(gestureRecognizer.translation(in: self.view).y / terminalsCarrousel.view.frame.height)
        
        if terminalsCarrousel.view.frame.height == 0 && panDirection == .down {
          alphaPercentage = 1
        } else if terminalsCarrousel.view.frame.height == 0 && panDirection == .up {
          alphaPercentage = 0
        }
        
        if panDirection == .down {
          /// Progressivelly increase the alpha when the view is appearing
          terminalsCarrousel.view.alpha = 1 - alphaPercentage
        } else {
          /// Progressivelly increase the alpha when the view is appearing
          terminalsCarrousel.view.alpha = alphaPercentage
        }
        
        /// When following the finger down the alpha is decreasing, once it reaches the threshold of `0.1` hide the view finishing the interaction
        if terminalsCarrousel.view.alpha <= 0.1 && panDirection == .down {
          terminalsCarrousel.view.isHidden = true
        }
        
        /// Translated movement is only the initial position plus the recognized gesture
        translatedVerticalBottomLeftPosition.y = initialVerticalBottomLeftPosition.y
                                                  + gestureRecognizer.translation(in: view).y
        
        
        bottomLeftStackView.center.y = translatedVerticalBottomLeftPosition.y
        
      default: break
      }
    }
  }
}

extension UIView {
  /// Animate the appearance of an `UIView`
  func fadeIn(_ duration: TimeInterval? = 0.2, onCompletion: (() -> Void)? = nil) {
    self.alpha = 0
    self.isHidden = false
    UIView.animate(withDuration: duration!,
                   animations: { self.alpha = 1 },
                   completion: { (value: Bool) in
                    if let complete = onCompletion { complete() }
                   })
  }
  
  /// Animate the disappearance of an `UIView`
  func fadeOut(_ duration: TimeInterval? = 0.2, onCompletion: (() -> Void)? = nil) {
    UIView.animate(withDuration: duration!,
                   animations: { self.alpha = 0 },
                   completion: { (value: Bool) in
                    self.isHidden = true
                    if let complete = onCompletion { complete() }
                   })
  }
  
}
