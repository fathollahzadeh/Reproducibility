
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL 
        AND p.Score IS NOT NULL
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(uvs.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(uvs.DownVotesCount, 0) AS DownVotesCount,
        u.Views,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        UserVoteStats uvs ON u.Id = uvs.UserId
    WHERE 
        u.Reputation > 100
),
ConsolidatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        tu.DisplayName AS TopUser,
        tu.Reputation,
        tu.UpVotesCount,
        tu.DownVotesCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers tu ON rp.PostId IN (
            SELECT DISTINCT 
                p.Id 
            FROM 
                Posts p 
            JOIN 
                Votes v ON p.Id = v.PostId 
            WHERE 
                v.UserId = tu.UserId
        )
    WHERE 
        rp.ScoreRank = 1
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.ViewCount,
    cd.CreationDate,
    cd.Score,
    cd.TopUser,
    cd.Reputation,
    cd.UpVotesCount,
    cd.DownVotesCount,
    CASE 
        WHEN cd.UpVotesCount > cd.DownVotesCount THEN 'Positive'
        WHEN cd.UpVotesCount < cd.DownVotesCount THEN 'Negative'
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    ConsolidatedData cd
ORDER BY 
    cd.Score DESC, 
    cd.ViewCount DESC
LIMIT 10;
