WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
VoteStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UPS.TotalPosts, 0) AS TotalPosts,
    COALESCE(UPS.Questions, 0) AS Questions,
    COALESCE(UPS.Answers, 0) AS Answers,
    COALESCE(UPS.Wikis, 0) AS Wikis,
    COALESCE(UPS.TagWikis, 0) AS TagWikis,
    COALESCE(VS.TotalVotes, 0) AS TotalVotes,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes
FROM 
    Users U
LEFT JOIN 
    UserPostStats UPS ON U.Id = UPS.UserId
LEFT JOIN 
    VoteStats VS ON U.Id = VS.OwnerUserId
ORDER BY 
    TotalPosts DESC;