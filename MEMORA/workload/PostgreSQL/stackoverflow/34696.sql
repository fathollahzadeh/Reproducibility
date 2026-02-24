WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PostStatistics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
        LEFT JOIN Users u ON rp.OwnerUserId = u.Id
        LEFT JOIN Comments c ON rp.PostId = c.PostId
        LEFT JOIN (
            SELECT 
                v.PostId,
                SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
                SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
            FROM 
                Votes v
                JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
            GROUP BY 
                v.PostId
        ) v ON rp.PostId = v.PostId
    WHERE 
        rp.UserPostRank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, u.DisplayName, u.Reputation, v.UpVotes, v.DownVotes
),
TopPostStats AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS ViewRank
    FROM 
        PostStatistics ps
)
SELECT 
    tps.PostId,
    tps.Title,
    tps.CreationDate,
    tps.Score,
    tps.ViewCount,
    tps.OwnerDisplayName,
    tps.OwnerReputation,
    tps.CommentCount,
    tps.UpVotes,
    tps.DownVotes,
    CASE 
        WHEN tps.ScoreRank = 1 THEN 'Top Scored'
        WHEN tps.ViewRank = 1 THEN 'Most Viewed'
        ELSE 'Regular Post'
    END AS PostTypeIndicator
FROM 
    TopPostStats tps
WHERE 
    tps.OwnerReputation > 1000 
ORDER BY 
    tps.Score DESC, 
    tps.ViewCount DESC
LIMIT 10;