WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 4 THEN 1 ELSE 0 END) AS TagWikiExcerpts,
        SUM(CASE WHEN P.PostTypeId = 5 THEN 1 ELSE 0 END) AS TagWikis,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
), UserRanking AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TagWikiExcerpts,
        TagWikis,
        UpVotes,
        DownVotes,
        BadgesEarned,
        RANK() OVER (ORDER BY TotalPosts DESC, UpVotes - DownVotes DESC, BadgesEarned DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    Rank, 
    DisplayName, 
    TotalPosts, 
    Questions, 
    Answers, 
    TagWikiExcerpts, 
    TagWikis, 
    UpVotes, 
    DownVotes, 
    BadgesEarned
FROM 
    UserRanking
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
