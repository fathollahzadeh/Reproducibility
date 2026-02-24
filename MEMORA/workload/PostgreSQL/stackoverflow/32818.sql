
WITH RankedQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopQuestions AS (
    SELECT 
        *,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedQuestions
    WHERE 
        Rank <= 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS HighestBadge
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.NetVotes,
    ub.BadgeCount,
    ub.HighestBadge,
    us.DisplayName,
    us.TotalScore
FROM 
    TopQuestions tq
JOIN 
    Posts p ON tq.PostId = p.Id
JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
JOIN 
    UserScore us ON p.OwnerUserId = us.UserId
ORDER BY 
    tq.NetVotes DESC, 
    tq.CreationDate DESC;
