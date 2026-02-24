WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Title IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Tags,
        STRING_AGG(b.Name, ', ') AS UserBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
    WHERE 
        rp.Rank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.CreationDate, rp.OwnerUserId, rp.Tags
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 2 
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
FinalBenchmark AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CreationDate,
        us.DisplayName AS AnswererName,
        us.Reputation AS AnswererReputation,
        us.UserId,
        tp.UserBadges,
        (us.TotalUpvotes - us.TotalDownvotes) AS NetVotes
    FROM 
        TopPosts tp
    JOIN 
        UserStats us ON tp.OwnerUserId = us.UserId
)
SELECT 
    fb.PostId,
    fb.Title,
    fb.Score,
    fb.CreationDate,
    fb.AnswererName,
    fb.AnswererReputation,
    fb.UserBadges,
    fb.NetVotes
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.Score DESC, fb.CreationDate DESC
LIMIT 20;