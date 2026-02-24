
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClassSum
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate BETWEEN DATE('2024-10-01') - INTERVAL '1 year' AND DATE('2024-10-01')
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.AcceptedAnswerId
),
EnhancedRankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.Upvotes,
        pd.Downvotes,
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY pd.AnswerCount DESC) AS AnswerRank
    FROM PostDetails pd
)
SELECT 
    ub.UserId,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(er.PostId, -1) AS TopPostId,
    er.Title AS TopPostTitle,
    er.ViewCount AS TopPostViewCount,
    er.AnswerCount AS TopPostAnswerCount,
    er.CommentCount AS TopPostCommentCount,
    (ub.TotalBadgeClassSum + COALESCE(er.Upvotes, 0) - COALESCE(er.Downvotes, 0)) AS UserEngagementScore,
    CASE
        WHEN ub.TotalBadgeClassSum IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus,
    CASE 
        WHEN ub.TotalBadgeClassSum IS NULL AND er.PostId IS NULL THEN 'No Engagement'
        WHEN ub.TotalBadgeClassSum IS NOT NULL AND er.PostId IS NULL THEN 'Engaged, No Posts'
        ELSE 'Engaged with Posts'
    END AS EngagementStatus
FROM UserBadges ub
LEFT JOIN EnhancedRankedPosts er ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = er.PostId LIMIT 1)
ORDER BY UserEngagementScore DESC, BadgeStatus, EngagementStatus;
