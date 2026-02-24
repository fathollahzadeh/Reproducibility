
WITH RecursiveTagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        t.Id, t.TagName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS AuthorName,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
ClosedPostStats AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(pr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes pr ON pr.Id = CAST(ph.Comment AS INTEGER)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rtag.TagName,
    rtag.PostCount,
    rtag.TotalUpvotes,
    rtag.TotalDownvotes,
    COALESCE(cp.CloseCount, 0) AS NumberOfClosures,
    COALESCE(cp.CloseReasons, 'No Reasons') AS ClosureReasons,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.AuthorName AS RecentPostAuthor
FROM 
    RecursiveTagStats rtag
LEFT JOIN 
    ClosedPostStats cp ON rtag.TagId = cp.PostId
LEFT JOIN 
    RecentPosts rp ON rp.PostId = (
        SELECT PostId 
        FROM RecentPosts 
        WHERE RecentPostRank = 1
    )
WHERE 
    rtag.Rank <= 5
ORDER BY 
    rtag.TotalUpvotes DESC, rtag.PostCount DESC;
