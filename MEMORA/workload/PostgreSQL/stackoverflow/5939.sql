WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5'
            WHEN rp.Rank <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS RankBracket
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
),
VotesAggregated AS (
    SELECT
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FinalReport AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.OwnerDisplayName,
        ps.ViewCount,
        ps.Score,
        ps.RankBracket,
        va.VoteCount,
        va.UpVotes,
        va.DownVotes
    FROM 
        PostStatistics ps
    JOIN 
        VotesAggregated va ON ps.PostId = va.PostId
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.OwnerDisplayName,
    fr.ViewCount,
    fr.Score,
    fr.RankBracket,
    fr.VoteCount,
    fr.UpVotes,
    fr.DownVotes
FROM 
    FinalReport fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 50;