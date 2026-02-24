WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        COALESCE(votes.UpVotes, 0) AS UpVotes,
        COALESCE(votes.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) votes ON p.Id = votes.PostId
    WHERE 
        p.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
), 
PostHistoryRecent AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days'
),
PostsWithComments AS (
    SELECT 
        p.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts p
    LEFT JOIN Comments c ON p.PostId = c.PostId
    GROUP BY 
        p.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        pr.CommentCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.UpVotes DESC, Pr.CommentCount DESC) AS ScoreRank
    FROM 
        RankedPosts rp
    JOIN 
        PostsWithComments pr ON rp.PostId = pr.PostId
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Body,
    fr.Score AS TotalScore,
    fr.UpVotes,
    fr.DownVotes,
    fr.CommentCount,
    ph.HistoryDate,
    ph.UserDisplayName AS Editor,
    ph.Comment AS EditComment
FROM 
    FinalResults fr
LEFT JOIN 
    PostHistoryRecent ph ON fr.PostId = ph.PostId
WHERE 
    ph.HistoryDate IS NOT NULL 
    OR (fr.UpVotes > 10 AND fr.CommentCount > 5)
ORDER BY 
    fr.ScoreRank, 
    fr.UpVotes DESC,
    fr.CommentCount DESC;