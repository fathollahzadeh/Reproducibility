
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (4,5) THEN 1 ELSE 0 END) AS TagWikiCount,
        AVG(VB.BountyAmount) AS AvgBountyAmount,
        MAX(U.CreationDate) AS AccountCreationDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId IN (8, 9) 
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        COUNT(C.ID) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.Score > 0
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TagWikiCount,
        AvgBountyAmount,
        AccountCreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStatistics
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    P.Title AS PopularPost,
    P.CommentCount AS PostCommentCount,
    P.UpVoteCount AS PostUpVoteCount,
    P.DownVoteCount AS PostDownVoteCount,
    U.AccountCreationDate AS UserAccountCreationDate
FROM 
    TopUsers U
JOIN 
    PostEngagement P ON U.PostCount > 5
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.Reputation DESC, P.UpVoteCount DESC
FETCH FIRST 50 ROWS ONLY;
