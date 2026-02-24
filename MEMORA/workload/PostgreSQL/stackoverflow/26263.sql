
WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(B.Class) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserEngagement
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.AnswerCount,
    TU.QuestionCount,
    TU.CommentCount,
    TU.UpvoteCount,
    TU.DownvoteCount,
    TU.BadgeCount,
    PH.UserDisplayName AS LastEditedBy,
    PH.CreationDate AS LastEditedDate,
    COUNT(*) OVER (PARTITION BY TU.UserId) AS EditCount
FROM 
    TopUsers TU
LEFT JOIN 
    PostHistory PH ON TU.UserId = PH.UserId
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC, EditCount DESC;
