
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), 
PostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS QuestionCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        SUM(CASE WHEN rp.RN = 1 THEN 1 ELSE 0 END) AS MostRecentQuestionsCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    ps.UserId,
    ps.DisplayName,
    ps.QuestionCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.BadgeCount,
    ra.CommentCount,
    ra.PostHistoryCount,
    (ps.UpVotes - ps.DownVotes) AS VoteBalance,
    DENSE_RANK() OVER (ORDER BY (ps.UpVotes - ps.DownVotes) DESC) AS VoteRank
FROM 
    PostStats ps
LEFT JOIN 
    UserBadges ub ON ps.UserId = ub.UserId
LEFT JOIN 
    RecentActivity ra ON ps.UserId = ra.OwnerUserId
WHERE 
    ps.QuestionCount > 0
ORDER BY 
    VoteBalance DESC, ps.QuestionCount DESC;
