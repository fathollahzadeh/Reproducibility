WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' AND
        p.ViewCount IS NOT NULL
),
TopUserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        u.Reputation > 1000 /* focusing on higher reputation users */
    GROUP BY 
        u.Id, u.DisplayName
),
VoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
    GROUP BY 
        v.PostId
    HAVING 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) > 0 /* Filtering for positively scored posts */
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT CASE WHEN pht.Name LIKE '%Title%' THEN 1 END) AS TitleEdits,
        COUNT(DISTINCT CASE WHEN pht.Name LIKE '%Body%' THEN 1 END) AS BodyEdits,
        MIN(ph.CreationDate) AS FirstEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    te.TotalViews,
    te.TotalComments,
    phs.TitleEdits,
    phs.BodyEdits,
    phs.FirstEditDate,
    vc.UpVotes,
    vc.DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUserEngagement te ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = te.UserId)
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
LEFT JOIN 
    VoteCounts vc ON rp.PostId = vc.PostId
WHERE 
    rp.RankByScore <= 5 /* Top 5 posts per type */
ORDER BY 
    rp.PostId, te.TotalViews DESC NULLS LAST
FETCH NEXT 100 ROWS ONLY;