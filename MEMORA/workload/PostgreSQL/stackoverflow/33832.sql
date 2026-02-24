
WITH RECURSIVE UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.Location,
        U.AboutMe,
        0 AS TotalVotes,
        0 AS UpVotesCount,
        0 AS DownVotesCount,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        U.Location,
        U.AboutMe,
        UV.TotalVotes + COALESCE(V.BountyAmount, 0) AS TotalVotes,
        UV.UpVotesCount + CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END AS UpVotesCount,
        UV.DownVotesCount + CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END AS DownVotesCount,
        UV.Level + 1
    FROM 
        Users U
    INNER JOIN 
        Votes V ON U.Id = V.UserId
    INNER JOIN 
        UserVoteStats UV ON U.Id = UV.UserId
    WHERE 
        UV.Level < 10
),
FilteredPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Score + COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY P.Id), 0) AS TotalUpVotes,
        P.Body,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > '2023-01-01'
        AND P.Score > 10
),
TopUsers AS (
    SELECT 
        U.Id, 
        U.DisplayName, 
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS RN
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL 
)
SELECT 
    U.DisplayName AS TopUser,
    F.Title AS PopularPost,
    F.CreationDate AS PostDate,
    F.TotalUpVotes AS PopularPostUpVotes,
    U.Reputation AS UserReputation,
    COALESCE(F.AnswerCount, 0) AS AnswersToPost,
    COALESCE(F.CommentCount, 0) AS CommentsOnPost,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS UserBadges,
    (SELECT STRING_AGG(Name, ', ') 
     FROM Badges B 
     WHERE B.UserId = U.Id) AS BadgeNames,
    CASE 
        WHEN U.Views IS NULL THEN 'No Views' 
        ELSE CAST(U.Views AS VARCHAR) 
    END AS UserViewCount
FROM 
    TopUsers U
LEFT JOIN 
    FilteredPosts F ON U.Id = F.OwnerUserId
WHERE 
    U.RN <= 10
ORDER BY 
    U.Reputation DESC, F.TotalUpVotes DESC;
