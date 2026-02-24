
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        rn <= 5
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostStatistics AS (
    SELECT 
        t.PostId,
        t.Title,
        t.Score,
        t.ViewCount,
        t.CreationDate,
        t.OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN COALESCE(v.UpVotes, 0) + COALESCE(v.DownVotes, 0) = 0 
            THEN NULL 
            ELSE (COALESCE(v.UpVotes, 0) * 100.0) / (COALESCE(v.UpVotes, 0) + COALESCE(v.DownVotes, 0)) 
        END AS UpVotePercentage
    FROM 
        TopPosts t
    LEFT JOIN 
        PostVoteCounts v ON t.PostId = v.PostId
)
SELECT 
    ps.OwnerDisplayName,
    ps.Title,
    ps.CreationDate,
    ps.UpVotePercentage,
    ps.ViewCount,
    CASE 
        WHEN ps.Score > 10 THEN 'High' 
        WHEN ps.Score BETWEEN 1 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS ScoreTier,
    (SELECT COUNT(*) 
     FROM PostHistory pH 
     WHERE pH.PostId = ps.PostId 
       AND pH.CreationDate > CURRENT_DATE - INTERVAL '6 MONTH') AS RecentEdits
FROM 
    PostStatistics ps
ORDER BY 
    ps.UpVotePercentage DESC NULLS LAST,
    ps.ViewCount DESC;
