
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerUserId AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        RankedPosts rp
    INNER JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank <= 5
), 
PostStatistics AS (
    SELECT 
        tp.UserId,
        tp.DisplayName,
        SUM(tp.Score) AS TotalScore,
        COUNT(tp.PostId) AS PostCount,
        AVG(tp.ViewCount) AS AvgViewCount
    FROM 
        TopPosts tp
    GROUP BY 
        tp.UserId, 
        tp.DisplayName
), 
TopVoters AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v 
    INNER JOIN 
        Posts p ON v.PostId = p.Id 
    WHERE 
        p.PostTypeId = 1 AND 
        v.VoteTypeId IN (2, 3) /* Only upvotes and downvotes */
    GROUP BY 
        v.UserId
),
CombinedStats AS (
    SELECT 
        ps.UserId,
        ps.DisplayName,
        ps.TotalScore,
        ps.PostCount,
        ps.AvgViewCount,
        COALESCE(tv.VoteCount, 0) AS VoteCount
    FROM 
        PostStatistics ps
    LEFT JOIN 
        TopVoters tv ON ps.UserId = tv.UserId
)

SELECT 
    cs.DisplayName,
    cs.TotalScore,
    cs.PostCount,
    cs.AvgViewCount,
    cs.VoteCount
FROM 
    CombinedStats cs
WHERE 
    cs.TotalScore > 1000
ORDER BY 
    cs.TotalScore DESC, 
    cs.PostCount DESC;
