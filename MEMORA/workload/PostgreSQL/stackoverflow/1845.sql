WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts po WHERE po.OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS CommentCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    us.DisplayName AS TopContributor,
    us.Reputation AS ContributorReputation,
    pvs.UpVotes,
    pvs.DownVotes,
    (pvs.UpVotes - pvs.DownVotes) AS NetVotes,
    CASE 
        WHEN pvs.TotalVotes IS NULL THEN 'No Votes'
        ELSE 'Votes Present'
    END AS VoteStatus
FROM 
    TopPosts tp
JOIN 
    UserStats us ON us.PostCount = (SELECT MAX(PostCount) FROM UserStats)
LEFT JOIN 
    PostVoteSummary pvs ON pvs.PostId = tp.Id
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;