WITH UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostCounts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS ClosedPostCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY ph.UserId
),
UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.GoldCount, 0) AS GoldCount,
        COALESCE(ub.SilverCount, 0) AS SilverCount,
        COALESCE(ub.BronzeCount, 0) AS BronzeCount,
        COALESCE(pc.QuestionCount, 0) AS QuestionCount,
        COALESCE(pc.AnswerCount, 0) AS AnswerCount,
        COALESCE(pc.TotalBounties, 0) AS TotalBounties,
        COALESCE(cp.ClosedPostCount, 0) AS ClosedPostCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostCounts pc ON u.Id = pc.OwnerUserId
    LEFT JOIN ClosedPosts cp ON u.Id = cp.UserId
),
FinalStats AS (
    SELECT 
        us.DisplayName,
        us.QuestionCount,
        us.AnswerCount,
        us.TotalBounties,
        us.ClosedPostCount,
        ROW_NUMBER() OVER (ORDER BY us.QuestionCount DESC, us.AnswerCount DESC) AS Rank
    FROM UserStats us
)
SELECT 
    fs.DisplayName,
    fs.QuestionCount,
    fs.AnswerCount,
    fs.TotalBounties,
    fs.ClosedPostCount,
    CASE 
        WHEN fs.ClosedPostCount > 10 THEN 'Expert'
        WHEN fs.ClosedPostCount BETWEEN 5 AND 10 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM FinalStats fs
WHERE fs.ClosedPostCount IS NOT NULL
ORDER BY fs.Rank
LIMIT 100;
