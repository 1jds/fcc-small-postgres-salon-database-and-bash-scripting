#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ Sharon's Salon ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

MAIN_MENU() {
    # displays any message passed as an argument when MAIN_MENU is invoked
    if [[ $1 ]]; then
        echo -e "\n$1"
    fi

    # get available services from the database
    AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
    # count the number of services for verification of later user menu input
    AVAILABLE_SERVICES_COUNT=$($PSQL "SELECT COUNT(service_id) FROM services WHERE name IS NOT NULL")

    # display available services for user selection
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME; do
        echo "$SERVICE_ID) $NAME"
    done

    USER_INPUT
}

USER_INPUT() {
    # the user makes a service selection
    read SERVICE_ID_SELECTED
    GET_SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    
    # checks to see if the user input is a valid selection
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
        # send to main menu
        MAIN_MENU "I could not find that service. What would you like today?"
    elif [[ $SERVICE_ID_SELECTED -gt $AVAILABLE_SERVICES_COUNT ]]; then
        MAIN_MENU "I could not find that service. What would you like today?"
    else
        # ask user's phone number for unique identification
        echo "What's your phone number?"
        read CUSTOMER_PHONE

        # check customer exists, and find their name in the same step
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        # if customer doesn't exist
        if [[ -z $CUSTOMER_NAME ]]; then
            ADD_CUSTOMER
        fi

        # get user's desired appointment/service time
        echo -e "\nWhat time would you like your $(echo $GET_SERVICE_NAME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
        read SERVICE_TIME

        # get customer_id preparatory to creating their appointment row
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        # create row in appointments table
        INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
        # give message to customer upon successful completion
        echo -e "I have put you down for a $(echo $GET_SERVICE_NAME | sed -r 's/^ *| *$//g') at $(echo $SERVICE_TIME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
    fi
}

ADD_CUSTOMER() {
    # get new customer's name
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    # insert new customer's details into database
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
}

MAIN_MENU
