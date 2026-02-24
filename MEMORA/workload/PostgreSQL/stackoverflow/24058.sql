
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        RANK() OVER (ORDER BY COUNT(B.Id) DESC) AS BadgeRank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        COALESCE(GoldBadges, 0) AS GoldBadges,
        COALESCE(SilverBadges, 0) AS SilverBadges,
        COALESCE(BronzeBadges, 0) AS BronzeBadges
    FROM UserBadges
    WHERE BadgeCount > 0
),
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(P.Id) AS TotalPosts
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.OwnerUserId
),
FinalReport AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserName,
        COALESCE(PA.CommentCount, 0) AS CommentsMade,
        COALESCE(PA.UpVoteCount, 0) AS UpVotesGiven,
        COALESCE(PA.DownVoteCount, 0) AS DownVotesGiven,
        COALESCE(PA.TotalScore, 0) AS TotalScore,
        COALESCE(PA.TotalPosts, 0) AS PostsCreated,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(UB.GoldBadges, 0) AS GoldBadges,
        COALESCE(UB.SilverBadges, 0) AS SilverBadges,
        COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN PostActivity PA ON U.Id = PA.OwnerUserId
    LEFT JOIN TopUsers UB ON U.Id = UB.UserId
)
SELECT 
    UserName,
    COUNT(UserId) AS UserCount,
    AVG(TotalScore) AS AverageScore,
    SUM(CommentsMade) AS TotalComments,
    SUM(UpVotesGiven) AS TotalUpVotes,
    SUM(DownVotesGiven) AS TotalDownVotes,
    SUM(TotalBadges) AS OverallBadges,
    STRING_AGG(DISTINCT CONCAT('Gold: ', CAST(GoldBadges AS TEXT), ', Silver: ', CAST(SilverBadges AS TEXT), ', Bronze: ', CAST(BronzeBadges AS TEXT)), '; ') AS BadgeSummary
FROM FinalReport
GROUP BY UserName
HAVING AVG(TotalScore) > 0 AND SUM(CommentsMade) > 1
ORDER BY AverageScore DESC, UserCount DESC
LIMIT 10;
