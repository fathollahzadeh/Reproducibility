WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
),
UserVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN v.VoteTypeId IN (1, 4) THEN 1 END) AS AcceptedVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ups.Upvotes,
        ups.Downvotes,
        ups.AcceptedVotes,
        pha.HistoryTypes,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.ViewCount ASC) AS OverallRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserVoteSummary ups ON rp.PostId = ups.PostId
    LEFT JOIN 
        PostHistoryAnalysis pha ON rp.PostId = pha.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.Upvotes,
    tp.Downvotes,
    tp.AcceptedVotes,
    tp.HistoryTypes,
    CASE 
        WHEN tp.OverallRank <= 10 THEN 'Top 10 Posts' 
        ELSE 'Other Posts' 
    END AS RankCategory,
    COALESCE(H2.Title, 'No Parent') AS ParentPostTitle
FROM 
    TopPosts tp
LEFT JOIN 
    Posts H1 ON tp.PostId = H1.Id AND H1.PostTypeId = 2 
LEFT JOIN 
    Posts H2 ON H1.ParentId = H2.Id 
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
ORDER BY 
    tp.OverallRank;