WITH User_Scores AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
Post_Statistics AS (
    SELECT 
        P.Id AS PostId, 
        P.Score AS PostScore, 
        P.Title, 
        P.CreationDate, 
        P.LastActivityDate, 
        P.AcceptedAnswerId, 
        U.DisplayName AS OwnerDisplayName, 
        P.ViewCount, 
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
),
Top_Users AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes - DownVotes AS NetVotes, 
        TotalPosts, 
        TotalComments 
    FROM 
        User_Scores 
    WHERE 
        TotalPosts > 0 
    ORDER BY 
        NetVotes DESC 
    LIMIT 10
)
SELECT 
    PU.PostId, 
    PU.Title, 
    PU.PostScore, 
    PU.CreationDate, 
    PU.OwnerDisplayName, 
    PU.ViewCount, 
    TU.DisplayName AS TopUserName, 
    TU.NetVotes, 
    TU.TotalPosts, 
    TU.TotalComments
FROM 
    Post_Statistics PU
JOIN 
    Top_Users TU ON PU.OwnerDisplayName = TU.DisplayName
ORDER BY 
    PU.PostScore DESC, 
    PU.ViewCount DESC;
