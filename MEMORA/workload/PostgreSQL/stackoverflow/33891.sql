WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '>')) AS TagName) t ON true
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
RecentUserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostCount,
        MAX(p.Score) AS MaxPostScore,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 50 
    GROUP BY 
        u.Id
),
PostHistoryAnalysis AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS TotalCloseHistory
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.TotalBounties,
    ru.PostCount,
    ru.MaxPostScore,
    ru.LastActivity,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score AS PostScore,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pha.LastEditDate,
    pha.EditComments,
    pha.TotalCloseHistory,
    CASE 
        WHEN pha.TotalCloseHistory > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RecentUserEngagement ru
JOIN 
    RankedPosts rp ON ru.UserId = rp.RankByUser
LEFT JOIN 
    PostHistoryAnalysis pha ON rp.PostId = pha.PostId
WHERE 
    rp.RankByUser = 1 
ORDER BY 
    ru.Reputation DESC, 
    ru.PostCount DESC, 
    rp.Score DESC;