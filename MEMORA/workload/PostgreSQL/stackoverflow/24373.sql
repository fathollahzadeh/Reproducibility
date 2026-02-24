WITH RecursivePostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COALESCE(votes.UpVotes, 0) AS UpVotes,
        COALESCE(votes.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate) AS EntryRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentTotal,
        COALESCE(ph.TotalEdits, 0) AS EditHistory
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM Votes 
         GROUP BY PostId) votes ON p.Id = votes.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS TotalEdits 
         FROM PostHistory 
         WHERE PostHistoryTypeId IN (4, 5, 6) 
         GROUP BY PostId) ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
MaxScoreCTE AS (
    SELECT 
        PostId, 
        MAX(Score) AS MaxScore FROM RecursivePostAnalysis 
    GROUP BY PostId
),
TopPosts AS (
    SELECT 
        r.Title,
        r.Score,
        r.ViewCount,
        r.UpVotes,
        r.DownVotes,
        r.CommentTotal,
        (r.UpVotes - r.DownVotes) AS NetVotes,
        AVG(r.EditHistory) OVER () AS AvgEdits,
        CASE 
            WHEN r.Score = (SELECT MAX(Score) FROM RecursivePostAnalysis) THEN 'Top Performer'
            ELSE 'Regular Post'
        END AS PostType
    FROM 
        RecursivePostAnalysis r
    JOIN 
        MaxScoreCTE m ON r.PostId = m.PostId
    WHERE 
        r.EntryRank = 1
    ORDER BY 
        r.Score DESC
)
SELECT 
    *,
    CASE 
        WHEN NetVotes IS NULL THEN 'No Votes'
        WHEN NetVotes > 0 THEN 'Positive Feedback'
        WHEN NetVotes < 0 THEN 'Negative Feedback'
        ELSE 'Neutral' 
    END AS VoteFeedback,
    CASE 
        WHEN CommentTotal < AVG(CommentTotal) OVER () THEN 'Needs Attention'
        WHEN CommentTotal > AVG(CommentTotal) OVER () THEN 'Engaged Discussion'
        ELSE 'Moderate Engagement' 
    END AS EngagementStatus
FROM 
    TopPosts
WHERE 
    PostType = 'Top Performer'
OR (CommentTotal >= 10 AND NetVotes IS NOT NULL)
ORDER BY 
    ViewCount DESC;