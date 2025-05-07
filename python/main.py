import schedule 
import time
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
import requests

def check_internet():
    print("check internet...")
    try:
        req = requests.get("https://www.google.com", allow_redirects=False)
        if req.status_code == 200:
            print("Internet is connected.")
    except requests.exceptions.RequestException as e:
        print(f"Error checking internet connection : {e}")
        try:
            reqKKU = requests.get("https://login.kku.ac.th", allow_redirects=False)
            print(reqKKU)
            if reqKKU.status_code != 302:
                print("Internet isn't connect to KKU Wifi")
            else:
                print("Internet is connect to KKU Wifi")
                login_to_sso()
        except Exception as E:
            print(f"Error : {E}")


def login_to_sso():
    driver = webdriver.Chrome()
    driver.get("https://login.kku.ac.th")

    username_field = driver.find_element(By.ID, "username")
    password_field = driver.find_element(By.ID, "password")


    username = ""
    password = ""
    username_field.send_keys(username)
    password_field.send_keys(password)
    login_button = driver.find_element(By.CLASS_NAME, "btn-info")
    login_button.click()

    driver.close()

    print("Connect successfully")



schedule.every(10).seconds.do(check_internet)

while True:
    schedule.run_pending()
    time.sleep(1)