
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.AcceptedAnswerId
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        up.BadgeCount,
        COUNT(DISTINCT rp.PostId) AS TotalQuestions,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        Users u
    JOIN 
        UserBadges up ON u.Id = up.UserId
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, up.BadgeCount
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.TotalQuestions,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM 
    TopUsers tu
LEFT JOIN 
    ClosedPosts cp ON cp.PostId IN (SELECT PostId FROM RankedPosts WHERE OwnerUserId = tu.UserId)
ORDER BY 
    tu.TotalQuestions DESC, tu.TotalScore DESC;
