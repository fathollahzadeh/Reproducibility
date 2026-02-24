WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(v.VoteScore) AS AvgVoteScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteScore
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.UserId AS EditorId,
        ph.UserDisplayName AS EditorName,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 12)  
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.ClosedDate, '1970-01-01') AS ClosedDateFallback,
        p.AcceptedAnswerId,
        phs.EditorName,
        phs.EditRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryDetails phs ON p.Id = phs.PostId AND phs.EditRank = 1
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostLinkCounts AS (
    SELECT 
        pl.RelatedPostId,
        COUNT(*) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.RelatedPostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    COALESCE(rp.PostId, -1) AS PostId,
    COALESCE(rp.Title, 'No Recent Posts') AS Title,
    rp.CreationDate,
    rp.Score,
    rp.ClosedDateFallback,
    plc.LinkCount,
    CASE 
        WHEN rp.Title IS NOT NULL THEN 'Active'
        WHEN rp.ClosedDateFallback > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Recently Closed'
        ELSE 'Inactive'
    END AS PostStatus
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.AcceptedAnswerId
LEFT JOIN 
    PostLinkCounts plc ON rp.PostId = plc.RelatedPostId
WHERE 
    us.Reputation > (SELECT AVG(Reputation) FROM Users) 
ORDER BY 
    us.Reputation DESC, 
    rp.CreationDate DESC NULLS LAST
LIMIT 100;