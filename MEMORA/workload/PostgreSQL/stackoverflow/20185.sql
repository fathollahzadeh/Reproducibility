WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount,
        COALESCE(p.ClosedDate, p.LastActivityDate) AS LastRelevantDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TagStats AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(pl.Id) AS LinkCount
    FROM 
        Posts p
    JOIN 
        PostLinks pl ON p.Id = pl.PostId
    JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.Id, t.TagName
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostTypeId,
        rp.CreationDate,
        rp.Score,
        rp.Rank,
        pha.HistoryTypes,
        pha.HistoryCount,
        pha.LastHistoryDate,
        ts.TagName,
        ts.LinkCount,
        rp.CommentCount,
        rp.UpVoteCount - rp.DownVoteCount AS NetVotes,
        CASE 
            WHEN rp.LastRelevantDate IS NULL THEN 'No Activity'
            WHEN rp.LastRelevantDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month' THEN 'Recently Active'
            ELSE 'Inactive'
        END AS ActivityStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAggregates pha ON rp.PostId = pha.PostId
    LEFT JOIN 
        TagStats ts ON rp.PostId = ts.PostId
    WHERE 
        rp.Rank <= 10 
)
SELECT 
    *,
    CASE 
        WHEN HistoryCount > 5 AND NetVotes < 0 THEN 'Controversial Post'
        WHEN HistoryCount = 0 AND CommentCount > 0 THEN 'Need More Attention'
        ELSE 'Normal Post'
    END AS PostStatus
FROM 
    FinalResults
ORDER BY 
    Score DESC, ActivityStatus;