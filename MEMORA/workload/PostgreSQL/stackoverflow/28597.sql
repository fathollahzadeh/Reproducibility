WITH TagAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.Reputation) AS TotalReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(h.Id) AS HistoryCount,
        MAX(h.CreationDate) AS LastHistoryDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ta.PostId,
    ta.Title,
    ta.CreationDate,
    ta.CommentCount,
    ta.TotalBounty,
    ta.Tags,
    ubs.DisplayName,
    ubs.BadgeCount,
    ubs.TotalReputation,
    phs.HistoryCount,
    phs.LastHistoryDate
FROM 
    TagAnalysis ta
JOIN 
    Users u ON u.Id = ta.PostId 
JOIN 
    UserBadgeStats ubs ON u.Id = ubs.UserId
JOIN 
    PostHistoryStats phs ON ta.PostId = phs.PostId
ORDER BY 
    ta.CommentCount DESC, 
    ubs.TotalReputation DESC;