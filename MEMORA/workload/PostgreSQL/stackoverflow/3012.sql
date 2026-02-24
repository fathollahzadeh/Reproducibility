WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
InterestingPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        ps.VoteCount,
        ps.UpVotes,
        ps.DownVotes,
        COALESCE(ut.UserId, -1) AS TopUserId,
        ut.PostsCount,
        ut.TotalScore
    FROM 
        PostStats ps
    LEFT JOIN 
        TopUsers ut ON ps.PostId IN (
            SELECT p.Id 
            FROM Posts p 
            WHERE p.OwnerUserId = ut.UserId
        )
    WHERE 
        ps.VoteCount > 5 AND (ps.Score > 10 OR ps.AnswerCount > 5)
)
SELECT 
    ip.Title,
    ip.ViewCount,
    ip.Score,
    ip.AnswerCount,
    ip.VoteCount,
    ip.UpVotes,
    ip.DownVotes,
    CASE 
        WHEN ip.TopUserId IS NOT NULL THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributionType
FROM 
    InterestingPosts ip
ORDER BY 
    ip.Score DESC, ip.ViewCount DESC;