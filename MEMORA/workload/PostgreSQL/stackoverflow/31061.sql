
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS EditComment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
RecentPostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes, 
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)
SELECT 
    rpi.PostId,
    rpi.Title,
    rpi.CreationDate,
    rpi.NetVotes,
    rpi.CommentCount,
    rpi.Rank,
    rph.EditComment,
    pt.TagName,
    pt.TotalViews
FROM 
    RecentPostInfo rpi
LEFT JOIN 
    RecursivePostHistory rph ON rpi.PostId = rph.PostId AND rph.rn = 1
LEFT JOIN 
    PopularTags pt ON pt.TotalViews > 5000 
WHERE 
    rpi.Rank <= 5 
ORDER BY 
    rpi.NetVotes DESC;
