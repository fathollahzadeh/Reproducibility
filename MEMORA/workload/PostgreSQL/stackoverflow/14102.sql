
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.CreationDate,
        PT.Name AS PostType,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalScore,
    U.TotalBounties,
    P.PostId,
    P.Title,
    P.ViewCount,
    P.Score AS PostScore,
    P.AnswerCount AS PostAnswerCount,
    P.CommentCount AS PostCommentCount,
    P.FavoriteCount AS PostFavoriteCount,
    P.CreationDate AS PostCreationDate,
    P.PostType,
    V.UpVotes,
    V.DownVotes,
    V.TotalVotes
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    VoteStats V ON P.PostId = V.PostId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
