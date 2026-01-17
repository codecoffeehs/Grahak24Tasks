struct SharedTaskModel : Identifiable,Codable {
    let id :String
    var title : String
    var isCompleted: Bool
    var due : String
    
    var repeatType : RepeatType
    
    var categoryId : String
    var categoryTitle : String
    
    var color : String
    var icon : String
    
    var sharedByUserId : String
    
}
