
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.Score) AS MaxScore,
        MIN(p.CreationDate) AS FirstPostDate,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank,
        RANK() OVER (ORDER BY SUM(p.ViewCount) DESC) AS ViewRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseVoteCount,
        STRING_AGG(ph.Comment, ', ') AS CloseReasons
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(cp.CloseVoteCount, 0) AS CloseVoteCount
    FROM Posts p
    LEFT JOIN ClosedPosts cp ON p.Id = cp.PostId
),
CombinedResults AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.TotalPosts,
        ua.TotalViews,
        ua.QuestionCount,
        ua.AnswerCount,
        ub.TotalBadges,
        ub.BadgeNames,
        COALESCE(rp.Title, 'No Posts') AS TopPostTitle,
        COALESCE(rp.ViewCount, 0) AS TopPostViews,
        COALESCE(rp.ScoreRank, 0) AS TopPostScoreRank,
        COALESCE(rp.CloseVoteCount, 0) AS CloseVoteCount
    FROM UserActivity ua
    LEFT JOIN UserBadges ub ON ua.UserId = ub.UserId
    LEFT JOIN RankedPosts rp ON ua.UserId = (SELECT OwnerUserId FROM Posts ORDER BY Score DESC LIMIT 1) 
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalViews,
    QuestionCount,
    AnswerCount,
    TotalBadges,
    BadgeNames,
    TopPostTitle,
    TopPostViews,
    TopPostScoreRank,
    CloseVoteCount,
    CASE 
        WHEN CloseVoteCount > 0 THEN 'Yes'
        ELSE 'No'
    END AS HasBeenClosed,
    CASE 
        WHEN Reputation > 1000 AND TotalPosts > 10 THEN 'High Engagement'
        ELSE 'Regular User'
    END AS UserType
FROM CombinedResults
WHERE TotalViews > 100
ORDER BY Reputation DESC, TotalPosts DESC;
