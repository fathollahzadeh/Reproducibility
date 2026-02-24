
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
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
        UpVotes, 
        DownVotes, 
        Rank 
    FROM 
        UserStatistics
    WHERE 
        Rank <= 10
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.UserId AS ClosedBy,
        PH.CreationDate AS ClosedDate
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.AnswerCount,
    TU.QuestionCount,
    CP.Title AS ClosedPostTitle,
    CP.ClosedDate,
    (COALESCE(TU.UpVotes, 0) - COALESCE(TU.DownVotes, 0)) AS NetVotes
FROM 
    TopUsers TU
LEFT JOIN 
    ClosedPosts CP ON TU.UserId = CP.ClosedBy
ORDER BY 
    TU.Reputation DESC, 
    CP.ClosedDate DESC;
