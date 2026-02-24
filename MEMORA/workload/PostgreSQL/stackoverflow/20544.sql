
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS INT) = ct.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    au.DisplayName AS ActiveUser,
    rp.Title AS PostTitle,
    rp.ViewCount,
    rp.Score,
    rp.RankByViews,
    rp.RankByScore,
    COALESCE(pcr.CloseReasons, 'Not Closed') AS CloseReasons,
    au.VoteCount,
    au.UpVoteCount,
    au.DownVoteCount,
    au.TotalBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    ActiveUsers au ON rp.PostId IN (SELECT ParentId FROM Posts WHERE ParentId IS NOT NULL)
LEFT JOIN 
    PostClosureReasons pcr ON rp.PostId = pcr.PostId
WHERE 
    (au.UpVoteCount IS NULL OR au.UpVoteCount > 5) 
    AND (rp.Score IS NOT NULL OR rp.ViewCount > 100)
    AND (rp.RankByViews <= 10 OR rp.RankByScore <= 10)
ORDER BY 
    rp.RankByScore DESC NULLS LAST, 
    rp.RankByViews;
