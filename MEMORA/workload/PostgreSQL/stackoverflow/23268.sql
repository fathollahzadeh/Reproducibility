
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v 
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        pv.UpVotes,
        pv.DownVotes,
        CASE 
            WHEN pv.UpVotes + pv.DownVotes > 0 THEN (pv.UpVotes * 1.0 / (pv.UpVotes + pv.DownVotes) * 100)
            ELSE NULL 
        END AS VotePercentage,
        rp.CreationDate, 
        rp.RankByScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
),
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.VotePercentage,
        pd.CreationDate,
        pd.RankByScore,
        COALESCE(NULLIF(pd.VotePercentage, 0), 100) AS AdjustedVotePercentage
    FROM 
        PostDetails pd
    WHERE 
        pd.Score > 5 AND 
        pd.RankByScore = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        RANK() OVER (ORDER BY SUM(b.Class) DESC) AS BadgeRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(b.Class) > 0
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.AdjustedVotePercentage,
    tu.UserId,
    tu.DisplayName,
    tu.TotalBadges,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS ActualCommentCount,
    (SELECT CASE WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = fp.PostId AND v.UserId = -1) THEN 1 ELSE 0 END) AS IsVotedByCommunityUser
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.UpVotes > 20 AND u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
JOIN 
    TopUsers tu ON tu.UserId = u.Id
ORDER BY 
    fp.AdjustedVotePercentage DESC,
    fp.CreationDate DESC;
