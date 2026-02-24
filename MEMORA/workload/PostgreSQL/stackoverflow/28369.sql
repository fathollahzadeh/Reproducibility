WITH RankedPosts AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) as VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId
),

UserReputation AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        PostCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        UserReputation
)

SELECT 
    tp.DisplayName AS TopUserName,
    tp.PostCount AS QuestionsAsked,
    tp.TotalScore AS TotalReputationScore,
    rp.Title AS TopVotedQuestion,
    rp.VoteCount AS VotesReceived
FROM 
    TopUsers tp
JOIN 
    RankedPosts rp ON tp.UserId = rp.OwnerUserId
WHERE 
    tp.UserRank <= 10 
ORDER BY 
    rp.VoteCount DESC, tp.TotalScore DESC;