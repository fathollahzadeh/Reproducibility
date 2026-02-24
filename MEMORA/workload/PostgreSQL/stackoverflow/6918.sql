
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
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
        US.UserId, 
        US.DisplayName, 
        US.Reputation, 
        US.TotalPosts, 
        US.Questions, 
        US.Answers,
        US.Wikis,
        US.Upvotes,
        US.Downvotes,
        DENSE_RANK() OVER (ORDER BY US.Reputation DESC) AS Rank
    FROM 
        UserStats US
)
SELECT 
    T.UserId, 
    T.DisplayName, 
    T.Reputation, 
    T.TotalPosts, 
    T.Questions, 
    T.Answers, 
    T.Wikis, 
    T.Upvotes, 
    T.Downvotes
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Reputation DESC;
