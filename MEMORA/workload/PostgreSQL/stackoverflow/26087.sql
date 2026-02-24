WITH PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastEditDate,
        ph.CreationDate AS HistoryEditDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
    WHERE 
        p.PostTypeId = 1 
),
AggregatedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.CreationDate,
        COALESCE(MAX(pd.HistoryEditDate), pd.CreationDate) AS RecentEdit,
        SUM(pd.CommentCount) AS TotalComments,
        SUM(pd.UpVoteCount) AS TotalUpVotes,
        SUM(pd.DownVoteCount) AS TotalDownVotes
    FROM 
        PostDetail pd
    GROUP BY 
        pd.PostId, pd.Title, pd.OwnerDisplayName, pd.CreationDate
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalUpVotes DESC, TotalComments DESC) AS Rank
    FROM 
        AggregatedPosts
)
SELECT 
    rp.Rank,
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.RecentEdit,
    rp.TotalComments,
    rp.TotalUpVotes,
    rp.TotalDownVotes,
    CASE 
        WHEN rp.TotalUpVotes >= 20 THEN 'Popular'
        WHEN rp.TotalUpVotes BETWEEN 10 AND 19 THEN 'Trending'
        ELSE 'New'
    END AS PopularityStatus
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 100 
ORDER BY 
    rp.Rank;