WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '>'), 1) AS TagCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostID, 
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.TagCount,
        rp.Reputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
    LIMIT 10
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
        tp.PostID,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        pvc.UpVotes,
        pvc.DownVotes,
        tp.Reputation / (EXTRACT(EPOCH FROM cast('2024-10-01 12:34:56' as timestamp) - tp.CreationDate)/3600) AS ReputationPerHour 
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteCounts pvc ON tp.PostID = pvc.PostId
)
SELECT 
    ps.PostID,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.ReputationPerHour,
    CASE 
        WHEN ps.UpVotes > ps.DownVotes THEN 'Positive'
        WHEN ps.UpVotes < ps.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN ps.ReputationPerHour > 5 THEN 'High'
        WHEN ps.ReputationPerHour BETWEEN 2 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationGrowth
FROM 
    PostStatistics ps
ORDER BY 
    ps.ReputationPerHour DESC;