WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.CreationDate) AS CommentCount,
        COUNT(DISTINCT PH.Id) AS EditHistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.LastActivityDate, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY UpVotes - DownVotes DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.UpVotes,
    T.DownVotes,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.LastActivityDate,
    P.CommentCount,
    P.EditHistoryCount
FROM 
    TopUsers T
JOIN 
    PostActivity P ON P.OwnerDisplayName = T.DisplayName
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Rank, P.LastActivityDate DESC;
