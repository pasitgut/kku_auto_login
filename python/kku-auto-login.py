
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By


browser = webdriver.Firefox()

def is_kkuwifi() -> bool:
    try:
        r = requests.get("https://login.kku.ac.th", allow_redirects=False)
        if r.status_code != 302:
            print("Http Status is not 302")
            return False 
        else:
            print("Http Status is 302")
            return True
    except Exception as E:
        print("Error in is_kkuwifi :", E)


def is_connect() -> bool:
    try:
        r = requests.get("https://www.google.com", allow_redirects=False)
        if r.status_code != 200:
            print("Internet is not connect")
            return False 
        else:
            print("Intenet is online")
            return True
    except Exception as E:
        print("Error is_connect function :", E)
        return False   
    

def login(username: str, password: str) -> bool:
    try:
        browser.get("https://login.kku.ac.th")
        browser.find_element(By.ID, "username").send_keys(username)
        browser.find_element(By.ID, "password").send_keys(password)
        browser.find_element(By.CLASS_NAME, "btn-info").click()
        print("You logged in successfully")
        return True
    except Exception as E:
        print("Error in login function : ", E)
        return True 

def main():
    if is_kkuwifi() == True:
        print("Now you connect to kkuwifi but not login yet")
        if is_connect() == False:
            username = ""
            password = ""
            print("Now your internet is not online")
            login(username, password)

    else:
        print("You don't use kkuwifi now.")
    browser.close()

main()