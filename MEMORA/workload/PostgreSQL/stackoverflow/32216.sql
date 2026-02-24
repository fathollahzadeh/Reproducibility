
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        0 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        ph.Level + 1,
        p2.CreationDate
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.PostId
),
LatestVotes AS (
    SELECT
        v.PostId,
        MAX(v.CreationDate) AS LatestVoteDate,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    p.Id AS QuestionId,
    p.Title AS QuestionTitle,
    u.DisplayName AS Owner,
    ph.Level,
    COALESCE(lv.UpVotes, 0) AS UpVotes,
    COALESCE(lv.DownVotes, 0) AS DownVotes,
    COALESCE(ub.TotalBadges, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN ph.Level > 0 THEN 1 ELSE 0 END) AS AnswerCount
FROM 
    PostHierarchy ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    LatestVotes lv ON p.Id = lv.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, 
    p.Title, 
    u.DisplayName, 
    ph.Level, 
    lv.UpVotes, 
    lv.DownVotes, 
    ub.TotalBadges,
    ub.GoldBadges, 
    ub.SilverBadges, 
    ub.BronzeBadges
HAVING 
    COUNT(c.Id) > 0 OR SUM(CASE WHEN ph.Level > 0 THEN 1 ELSE 0 END) > 0
ORDER BY 
    ph.Level, 
    p.CreationDate DESC;
