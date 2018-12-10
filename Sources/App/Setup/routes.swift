import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.get("view") { req -> Future<View> in
        return try req.view().render("welcome")
    }
    
    router.get("keyboard") { req -> Future<View> in
        return try req.view().render("keyboard")
    }
    
    router.get("roboot") { req -> Future<View> in
        return try req.view().render("reboot")
    }

    // 御用创建和使用认证，后期可以移除
    let apiUserController = APIUserController()
    router.post("register", use: apiUserController.register)
    router.post("login", use: apiUserController.login)
    
    // 将中间组件添加到路由组中
    let tokenAuthenticationMiddleware = APIUser.tokenAuthMiddleware()
    let authedRoutes = router.grouped(tokenAuthenticationMiddleware)
    authedRoutes.get("profile", use: apiUserController.profile)
    authedRoutes.get("logout", use: apiUserController.logout)
    
    // 上传图片
    let uploadFileController = UploadFileController()
    try authedRoutes.register(collection: uploadFileController)
    
    // 测试用例
    let todoController = TodoController()
    try authedRoutes.register(collection: todoController)
    
    // 修改码
    let userCodeControlle = UserCodeController()
    try authedRoutes.register(collection: userCodeControlle)
    // 注册码
    let registerCodeComtroller = RegisterCodeController()
    try authedRoutes.register(collection: registerCodeComtroller)
    
    // MARK: User
    let userController = UserController()
    let userInfoController = UserInfoController()
    let studentController = StudentController()
    let focusController = FocusController()
    let collectionController = CollectionController()
    let honorController = HonorController()
    let messageController = MessageController()
    
    
    try authedRoutes.register(collection: userController)
    try authedRoutes.register(collection: userInfoController)
    try authedRoutes.register(collection: studentController)
    try authedRoutes.register(collection: focusController)
    try authedRoutes.register(collection: collectionController)
    try authedRoutes.register(collection: honorController)
    try authedRoutes.register(collection: messageController)
    
    
    // MARK: AD
    let adBannerController = ADBannerController()
    let notificationController = NotificationController()
    
    try authedRoutes.register(collection: adBannerController)
    try authedRoutes.register(collection: notificationController)
    
    
    // MARK: Campus
    let lessonController = LessonController()
    let lessonScheduleController = LessonScheduleController()
    let lessonGradeController = LessonGradeController()
    let raceController = RaceController()
    let academicController = AcademicController()
    let examinationController = ExaminationController()
    let speechController = SpeechController()
    let clubController = ClubController()
    let addressListController = AddressListController()
    let lostAndFoundController = LostAndFoundController()
    
    try authedRoutes.register(collection: lessonController)
    try authedRoutes.register(collection: lessonScheduleController)
    try authedRoutes.register(collection: lessonGradeController)
    try authedRoutes.register(collection: raceController)
    try authedRoutes.register(collection: academicController)
    try authedRoutes.register(collection: examinationController)
    try authedRoutes.register(collection: speechController)
    try authedRoutes.register(collection: clubController)
    try authedRoutes.register(collection: addressListController)
    try authedRoutes.register(collection: lostAndFoundController)
    
    
    // MARK: Communication
    let resourceController = ResourceController()
    let essayController = EssayController()
    let campusNewsController = CampusNewsController()
    let bookController = BookController()
    let questionController = QuestionController()
    let answerController = AnswerController()
    let experienceController = ExperienceController()
    let commentController = CommentController()
    
    try authedRoutes.register(collection: resourceController)
    try authedRoutes.register(collection: essayController)
    try authedRoutes.register(collection: campusNewsController)
    try authedRoutes.register(collection: bookController)
    try authedRoutes.register(collection: questionController)
    try authedRoutes.register(collection: answerController)
    try authedRoutes.register(collection: experienceController)
    try authedRoutes.register(collection: commentController)
    
    
    // MARK: LifeStyle
    let idleGoodController = IdleGoodController()
    let utilityBillController = UtilityBillController()
    let shootAndPrintController = ShootAndPrintController()
    let propertyManagerController = PropertyManagerController()
    let schoolStoreController = SchoolStoreController()
    let partTimeJobController = PartTimeJobController()
    let holidayController = HolidayController()
    
    try authedRoutes.register(collection: idleGoodController)
    try authedRoutes.register(collection: utilityBillController)
    try authedRoutes.register(collection: shootAndPrintController)
    try authedRoutes.register(collection: propertyManagerController)
    try authedRoutes.register(collection: schoolStoreController)
    try authedRoutes.register(collection: partTimeJobController)
    try authedRoutes.register(collection: holidayController)
    
}
