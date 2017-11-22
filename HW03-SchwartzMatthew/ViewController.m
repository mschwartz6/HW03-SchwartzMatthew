//
//  ViewController.m
//  HW03-SchwartzMatthew
//
//  Created by alive on 11/22/17.
//  Copyright © 2017 Matthew Schwartz. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>
#import "StudentInfo.h"
@interface ViewController ()
@property (strong, nonatomic) NSString *databaseName;
@property (strong, nonatomic) NSString *databasePath;
@property (strong, nonatomic) NSMutableArray *people;
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtAddress;
@property (weak, nonatomic) IBOutlet UITextField *txtPhone;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.people = [[NSMutableArray alloc]init];
    self.databaseName = @"MyStudents.db";
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    self.databasePath = [documentsDir stringByAppendingPathComponent:self.databaseName];
    [self copyDatabaseToDocumentsDirectory];
    [self readFromDatabase];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
-(void)copyDatabaseToDocumentsDirectory{
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager fileExistsAtPath:self.databasePath];
    if (success) return;
    
    NSString *databasePathFromApp = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:self.databaseName];
    [fileManager copyItemAtPath:databasePathFromApp toPath:self.databasePath error:nil];
}
-(void) readFromDatabase {
    [self.people removeAllObjects];
    sqlite3 *database;
    
    if (sqlite3_open([self.databasePath UTF8String], &database) == SQLITE_OK){
        char *sqlStatement = "select * from students";
        sqlite3_stmt *compiledStatement;
        
        if (sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK){
            while (sqlite3_step(compiledStatement)==SQLITE_ROW){
                char *n = (char *)sqlite3_column_text(compiledStatement, 1);
                char *a = (char *)sqlite3_column_text(compiledStatement, 2);
                char *p = (char *)sqlite3_column_text(compiledStatement, 3);
                NSString *name = [NSString stringWithUTF8String:n];
                NSString *address = [NSString stringWithUTF8String:a];
                NSString *phone = [NSString stringWithUTF8String:p];
                StudentInfo *aStudent = [[StudentInfo alloc]initWithData:name andAddress:address andPhone:phone];
                [self.people addObject:aStudent];
            }
        }
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}
-(BOOL)insertIntoDatabase:(StudentInfo *)aStudent{
    sqlite3 *database;
    BOOL returnCode = YES;
    
    if (sqlite3_open([self.databasePath UTF8String], &database) == SQLITE_OK)
    {
        char *sqlStatement = "insert into students values (NULL,?,?,?)";
        sqlite3_stmt *compiledStatement;
        if (sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL)==SQLITE_OK){
            sqlite3_bind_text(compiledStatement, 1, [aStudent.name UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 2, [aStudent.address UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement, 3, [aStudent.phone UTF8String], -1, SQLITE_TRANSIENT);
        }
        if (sqlite3_step(compiledStatement)!= SQLITE_DONE){
            NSLog(@"Error %s",sqlite3_errmsg(database));
            returnCode = NO;
        } else {
            NSLog(@"Inserted into row id: %lld",sqlite3_last_insert_rowid(database));
        }
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
    return returnCode;
}
-(void)deleteRecordInDatabase:(NSString*)name {
    sqlite3 *database;
    
    
    if (sqlite3_open([self.databasePath UTF8String], &database)==SQLITE_OK){
        NSString *deleteSQL = [NSString stringWithFormat:@"delete from students where name = '%@'",name];
        char *sqlDeleteStatement = (char*)[deleteSQL UTF8String];
        sqlite3_stmt *compiledStatement;
        if (sqlite3_prepare_v2(database, sqlDeleteStatement, -1, &compiledStatement, NULL)==SQLITE_OK){
            if (sqlite3_step(compiledStatement)==SQLITE_DONE){
                NSLog(@"%@'s record was deleted successfully",name);
                self.lblStatus.text = [NSString stringWithFormat:@"%@'s record was deleted successfully",name];
            } else {
                NSLog(@"%@'s record was not deleted.",name);
                self.lblStatus.text = @"Could not find record in database";
                
            }
        }
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}
-(void) findRecordInDatabase {
    
    sqlite3 *database;
    
    if (sqlite3_open([self.databasePath UTF8String], &database) == SQLITE_OK){
        NSString *selectSQL = [NSString stringWithFormat:@"select address,phone from students where name = '%@'",self.txtName.text ];
        char *sqlStatement = (char*)[selectSQL UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if (sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK){
            if (sqlite3_step(compiledStatement)==SQLITE_ROW){
               
                char *a = (char *)sqlite3_column_text(compiledStatement, 0);
                char *p = (char *)sqlite3_column_text(compiledStatement, 1);
                
                NSString *address = [NSString stringWithUTF8String:a];
                NSString *phone = [NSString stringWithUTF8String:p];
                self.txtAddress.text = address;
                self.txtPhone.text = phone;
                self.lblStatus.text = @"Match Found!";
            }
            else{  self.lblStatus.text = @"Match Not Found :(";}
        }
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
}

- (IBAction)addRecord:(UIButton *)sender {
    StudentInfo *person = [[StudentInfo alloc]initWithData:self.txtName.text andAddress:self.txtAddress.text andPhone:self.txtPhone.text];
    BOOL retCode = [self insertIntoDatabase:person];
    if (retCode ==NO){
        NSLog(@"Failed to add.");
        self.lblStatus.text = @"Failed to add a record";
    } else {
        NSLog(@"Added record succesfully");
        self.lblStatus.text = @"Added a record succesfully!";
    }
}
- (IBAction)findRecord:(UIButton *)sender {
    [self findRecordInDatabase];
}
- (IBAction)deleteRecord:(UIButton *)sender {
    [self readFromDatabase];
    for (int i = 0; i < [self.people count]; i++)
    {
        StudentInfo *aStudent = [self.people objectAtIndex:i];
        
        if ([aStudent.name isEqualToString:self.txtName.text] )
        {
            self.lblStatus.text = self.txtName.text;
            NSString *question = [NSString stringWithFormat: @"Are you sure you want to delete %@ from the records",self.txtName.text];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Attention!" message:question preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self deleteRecordInDatabase:self.txtName.text];                    }];
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
            [alert addAction:yesAction];
            [alert addAction:noAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            NSLog(@"%@'s record was not deleted.",self.txtName.text);
            self.lblStatus.text = @"Could not find record in database";
        }
    }
    
}
- (IBAction)clearFields:(UIButton *)sender {
    self.txtName.text = @"";
    self.txtPhone.text = @"";
    self.txtAddress.text = @"";
    self.lblStatus.text =@"";
}
-(IBAction)dismissKeyboard:(id)sender{
    [self.txtName resignFirstResponder];
    [self.txtAddress resignFirstResponder];
    [self.txtPhone resignFirstResponder];
}

@end
