
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate <= TIMESTAMP '2024-10-01 12:34:56'
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosePostReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.ViewCount,
    ts.TagName,
    ts.PostCount,
    ts.AvgViewCount,
    ue.DisplayName,
    ue.Upvotes,
    ue.Downvotes,
    ue.CommentCount,
    ue.BadgeCount,
    cpr.CloseReasonCount,
    cpr.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON ts.PostCount > 1
LEFT JOIN 
    UserEngagement ue ON ue.UserId = rp.PostId
LEFT JOIN 
    ClosePostReasons cpr ON cpr.PostId = rp.PostId
WHERE 
    rp.Rank <= 10  
    AND (rp.PostTypeId = 1 OR rp.PostTypeId = 2)  
ORDER BY 
    rp.ViewCount DESC, ue.Upvotes DESC NULLS LAST
LIMIT 100;
