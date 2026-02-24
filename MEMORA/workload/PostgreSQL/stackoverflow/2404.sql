WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes V WHERE V.UserId = U.Id) AS UpvoteCount,
        (SELECT SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) FROM Votes V WHERE V.UserId = U.Id) AS DownvoteCount,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS RN
    FROM 
        Users U
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        UpvoteCount,
        DownvoteCount
    FROM 
        UserStats
    WHERE 
        RN <= 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.AnswerCount,
        C.Text AS CommentText,
        COALESCE(CU.DisplayName, 'Anonymous') AS CommentUserName
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Users CU ON C.UserId = CU.Id
),
AggregatedPostInfo AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.OwnerUserId,
        PD.Score,
        PD.AnswerCount,
        STRING_AGG(PD.CommentText, ' | ') AS AllComments
    FROM 
        PostDetails PD
    GROUP BY 
        PD.PostId, PD.Title, PD.CreationDate, PD.OwnerUserId, PD.Score, PD.AnswerCount
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    AP.Title,
    AP.CreationDate,
    AP.Score,
    AP.AnswerCount,
    AP.AllComments,
    (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = TU.UserId) AS TotalPosts,
    (SELECT SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes V WHERE V.PostId = AP.PostId) AS PostUpvotes,
    (SELECT SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) FROM Votes V WHERE V.PostId = AP.PostId) AS PostDownvotes
FROM 
    TopUsers TU
JOIN 
    AggregatedPostInfo AP ON AP.OwnerUserId = TU.UserId
WHERE 
    AP.Score > 0
ORDER BY 
    TU.Reputation DESC, AP.CreationDate DESC;
