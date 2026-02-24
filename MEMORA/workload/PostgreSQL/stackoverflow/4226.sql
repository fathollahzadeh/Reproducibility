
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    u.DisplayName,
    ub.BadgeCount,
    pvs.UpVotes,
    pvs.DownVotes,
    COALESCE(rp.AcceptedAnswerId, 0) AS AcceptedAnswerId,
    STRING_AGG(c.Text, ', ') AS CommentTexts
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
LEFT JOIN 
    Comments c ON c.PostId = rp.Id
WHERE 
    rp.Rank <= 5 
GROUP BY 
    rp.Title, 
    rp.CreationDate,
    rp.Score,
    u.DisplayName,
    ub.BadgeCount,
    pvs.UpVotes,
    pvs.DownVotes,
    rp.AcceptedAnswerId
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
