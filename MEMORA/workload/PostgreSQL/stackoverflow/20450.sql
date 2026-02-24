
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByScoreViewCount,
        COALESCE(uh.UpVotes, 0) - COALESCE(uh.DownVotes, 0) AS NetVotes,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            UserId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            UserId) uh ON u.Id = uh.UserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            STRING_AGG(TagName, ', ') AS TagName 
         FROM 
            (SELECT 
               p.Id AS PostId, 
               TRIM(UNNEST(STRING_TO_ARRAY(p.Tags, '><'))) AS TagName 
             FROM Posts p) AS t
         GROUP BY PostId) t ON p.Id = t.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, uh.UpVotes, uh.DownVotes
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS HistoryChangeCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
PostsWithHistory AS (
    SELECT 
        rp.*,
        phd.LastClosedDate,
        phd.LastReopenedDate,
        phd.HistoryChangeCount,
        CASE 
            WHEN phd.HistoryChangeCount > 0 THEN 'Contains History Changes'
            ELSE 'No History Changes'
        END AS HistoryChangeStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetails phd ON rp.Id = phd.PostId
)
SELECT 
    pwh.Title,
    pwh.CreationDate,
    pwh.ViewCount,
    pwh.Score,
    pwh.RankByScoreViewCount,
    pwh.NetVotes,
    pwh.Tags,
    pwh.LastClosedDate,
    pwh.LastReopenedDate,
    pwh.HistoryChangeCount,
    pwh.HistoryChangeStatus
FROM 
    PostsWithHistory pwh
WHERE 
    (pwh.LastClosedDate IS NULL OR pwh.LastReopenedDate IS NOT NULL) 
    AND pwh.ViewCount > 100
ORDER BY 
    pwh.RankByScoreViewCount ASC, pwh.CreationDate DESC;
