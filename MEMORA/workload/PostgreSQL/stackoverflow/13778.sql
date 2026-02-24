WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
UserVoteStats AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.UserId
),
UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UPC.PostCount, 0) AS TotalPosts,
    COALESCE(UPC.Questions, 0) AS TotalQuestions,
    COALESCE(UPC.Answers, 0) AS TotalAnswers,
    COALESCE(UPC.Wikis, 0) AS TotalWikis,
    COALESCE(UVC.VoteCount, 0) AS TotalVotes,
    COALESCE(UVC.UpVotes, 0) AS TotalUpVotes,
    COALESCE(UVC.DownVotes, 0) AS TotalDownVotes,
    COALESCE(UBC.BadgeCount, 0) AS TotalBadges,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate
FROM 
    Users U
LEFT JOIN 
    UserPostCounts UPC ON U.Id = UPC.UserId
LEFT JOIN 
    UserVoteStats UVC ON U.Id = UVC.UserId
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
ORDER BY 
    TotalPosts DESC, Reputation DESC
LIMIT 100;